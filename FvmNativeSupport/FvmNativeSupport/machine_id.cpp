#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <iphlpapi.h>

#include <cstdio>
#include <cstring>
#include <string>

#include "Typedef.h"

#pragma comment(lib, "iphlpapi.lib")

// ─────────────────────────────────────────────────────────────
// 本机硬件标识。给授权模块的 auth_hwid() 当锚用。
//
// 为什么不能只用环境变量：COMPUTERNAME / PROCESSOR_IDENTIFIER /
// NUMBER_OF_PROCESSORS 这三个量在「ghost 克隆镜像」「同批装机」
// 「无盘网吧」里是完全一样的，算出来的识别码会全服撞成同一个。
// 这里取 SMBIOS 的 System UUID（主板级，一台一个），镜像克隆也不会重复。
// ─────────────────────────────────────────────────────────────

namespace {

// SMBIOS System Information（Type 1）里的 UUID 在规范里是 16 字节，
// 前三段是小端。全 0 / 全 FF 表示 OEM 没烧录，视为无效。
auto FormatUuid(const unsigned char* u) -> std::string {
  bool all_zero = true;
  bool all_ff = true;
  for (int i = 0; i < 16; ++i) {
    if (u[i] != 0x00) all_zero = false;
    if (u[i] != 0xFF) all_ff = false;
  }
  if (all_zero || all_ff) {
    return std::string();
  }

  char out[40] = {0};
  std::snprintf(out, sizeof(out),
                "%02X%02X%02X%02X-%02X%02X-%02X%02X-%02X%02X-%02X%02X%02X%02X%02X%02X",
                u[3], u[2], u[1], u[0],  // Data1，小端
                u[5], u[4],              // Data2，小端
                u[7], u[6],              // Data3，小端
                u[8], u[9],              // Data4，大端
                u[10], u[11], u[12], u[13], u[14], u[15]);
  return std::string(out);
}

// 用 GetSystemFirmwareTable('RSMB') 读原始 SMBIOS 表，手工走 Type 1。
// 不走 WMI（wmic 已在新系统里退役，且启动慢、依赖服务）。
auto ReadSmbiosUuid() -> std::string {
  const DWORD header_size = GetSystemFirmwareTable('RSMB', 0, nullptr, 0);
  if (header_size < 8) {
    return std::string();
  }

  std::string raw(header_size, '\0');
  const DWORD got = GetSystemFirmwareTable('RSMB', 0, &raw[0], header_size);
  if (got == 0 || got > header_size) {
    return std::string();
  }

  const auto* base = reinterpret_cast<const unsigned char*>(raw.data());
  // RawSMBIOSData：Used20CallingMethod(u8) Major(u8) Minor(u8) DmiRevision(u8) Length(u32) Table[]
  DWORD dmi_len = 0;
  std::memcpy(&dmi_len, base + 4, sizeof(dmi_len));
  if (dmi_len == 0 || static_cast<size_t>(8) + dmi_len > raw.size()) {
    return std::string();
  }

  const unsigned char* p = base + 8;
  const unsigned char* end = p + dmi_len;
  while (p + 4 <= end) {
    const unsigned char type = p[0];
    const unsigned char len = p[1];
    if (type == 127) {  // End-of-table
      break;
    }
    if (len < 4 || p + len > end) {
      break;
    }
    if (type == 1 && len >= 0x19) {  // System Information，UUID 在 0x08
      const std::string uuid = FormatUuid(p + 0x08);
      if (!uuid.empty()) {
        return uuid;
      }
    }
    // 跳过字符串区（双 NUL 结尾）
    const unsigned char* s = p + len;
    while (s + 1 < end && !(s[0] == 0 && s[1] == 0)) {
      ++s;
    }
    p = s + 2;
  }
  return std::string();
}

// 兜底：首块非环回、有真实 MAC 的网卡。无盘环境下每台机器的网卡各不相同。
auto ReadMac() -> std::string {
  const ULONG flags = GAA_FLAG_SKIP_ANYCAST | GAA_FLAG_SKIP_MULTICAST | GAA_FLAG_SKIP_DNS_SERVER;
  ULONG size = 0;
  if (GetAdaptersAddresses(AF_UNSPEC, flags, nullptr, nullptr, &size) != ERROR_BUFFER_OVERFLOW) {
    return std::string();
  }

  std::string buf(size, '\0');
  auto* addrs = reinterpret_cast<IP_ADAPTER_ADDRESSES*>(&buf[0]);
  if (GetAdaptersAddresses(AF_UNSPEC, flags, nullptr, addrs, &size) != NO_ERROR) {
    return std::string();
  }

  for (auto* a = addrs; a != nullptr; a = a->Next) {
    if (a->IfType == IF_TYPE_SOFTWARE_LOOPBACK) {
      continue;
    }
    if (a->PhysicalAddressLength != 6) {
      continue;
    }
    const unsigned char* m = a->PhysicalAddress;
    bool all_zero = true;
    for (int i = 0; i < 6; ++i) {
      if (m[i] != 0) {
        all_zero = false;
      }
    }
    if (all_zero) {
      continue;
    }
    char out[13] = {0};
    std::snprintf(out, sizeof(out), "%02X%02X%02X%02X%02X%02X", m[0], m[1], m[2], m[3], m[4], m[5]);
    return std::string(out);
  }
  return std::string();
}

}  // namespace

// 返回本机唯一硬件标识：
//   SMBIOS UUID   → "8C1F2A34-5678-90AB-CDEF-1234567890AB"
//   MAC 兜底      → "MAC-A1B2C3D4E5F6"
//   两者都拿不到  → ""（GML 侧会自动退化到环境指纹，不阻断启动）
// 进程内只算一次，返回的指针一直有效（GML 会自己拷贝字符串）。
GmlCallable const char* MachineUuid() {
  static const std::string cached = [] {
    const std::string uuid = ReadSmbiosUuid();
    if (!uuid.empty()) {
      return uuid;
    }
    const std::string mac = ReadMac();
    if (!mac.empty()) {
      return std::string("MAC-") + mac;
    }
    return std::string();
  }();
  return cached.c_str();
}
