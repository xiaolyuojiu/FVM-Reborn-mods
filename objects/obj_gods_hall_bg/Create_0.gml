image_xscale = 1.6;
image_yscale = 1.6;
instance_create_depth(1473, 284, depth - 1, obj_gods_hall_closer);
instance_create_depth(1296, 284, depth - 1, obj_gods_store_enter);
is_submenu_opened = false;
is_wishing = false;
wish_completed = true;
start_wishing = false;
start_wishing5 = false;
start_wishing50 = false;
skip_animation = false;
reward_id = [];
reward_list = [];
random_begin = false;
var wish = instance_create_depth((x + 2) - 300, 732, depth - 1, obj_gods_hall_wish);
wish.parent_gui = id;
wish.mode = 0;
var wish5 = instance_create_depth(x + 2, 732, depth - 1, obj_gods_hall_wish);
wish5.parent_gui = id;
wish5.mode = 1;
var wish50 = instance_create_depth(x + 2 + 300, 732, depth - 1, obj_gods_hall_wish);
wish50.parent_gui = id;
wish50.mode = 2;
var bag = instance_create_depth(x + 2, (room_height / 2) - 50, depth - 1, obj_gods_hall_bag);
bag.parent_gui = id;
bag.list_num = 0;

if (!variable_struct_exists(global.save_data.player, "wish_count"))
    global.save_data.player.wish_count = 0;
if (!variable_struct_exists(global.save_data.player, "pity_count"))
    global.save_data.player.pity_count = 0;

function gods_hall_get_random_reward()
{
    // 总权重 1000：金币 374 / 神谕之石 9 / 1~4星强化用卡 245 / 强化水晶 290 / 四叶草 82。
    //   卡包每种星只留一条（6 / 18 / 18 / 9 张），权重 1星 55 < 4星 60 < 2星 = 3星 65。
    var r = irandom(999);

    if (r < 244)
        return ["金币", 1000];
    else if (r < 334)
        return ["金币", 5000];
    else if (r < 374)
        return ["金币", 10000];
    else if (r < 379)
        return ["神谕之石", 5];
    else if (r < 382)
        return ["神谕之石", 10];
    else if (r < 383)
        return ["神谕之石", 25];
    else if (r < 438)
        return ["1星强化用卡", 6];
    else if (r < 503)
        return ["2星强化用卡", 18];
    else if (r < 568)
        return ["3星强化用卡", 18];
    else if (r < 628)
        return ["4星强化用卡", 9];
    else if (r < 728)
        return ["初级强化水晶", 25];
    else if (r < 768)
        return ["初级强化水晶", 50];
    else if (r < 838)
        return ["中级强化水晶", 25];
    else if (r < 868)
        return ["中级强化水晶", 50];
    else if (r < 938)
        return ["3级四叶草", 8];
    else if (r < 950)
        return ["4级四叶草", 5];
    else
        return ["高级强化水晶", 100];
}

/// @function gods_hall_apply_reward(_reward)
/// @desc 抽奖奖励入账。单抽 / 五连 / 五十连**共用这一处**（原来三段 switch 各抄一份，
///       加一种奖就得改三处、漏一处静默丢奖）。加奖 / 改奖只改这里 + 上面那个池子。
function gods_hall_apply_reward(_reward)
{
    var _name = _reward[0];
    var _qty  = _reward[1];
    var _p    = global.save_data.player;
    var _is_pity = (_p.wish_count >= 50);

    switch (_name)
    {
        case "金币":
            _p.gold += _qty;
            _p.wish_count++;
            break;

        case "神谕之石":
            add_material_amount("oracle_stone", _qty);
            _p.wish_count = 0;
            if (_is_pity) _p.pity_count++;
            break;

        case "1星强化用卡":
            add_material_amount("warcard_1", _qty);
            _p.wish_count++;
            break;

        case "2星强化用卡":
            add_material_amount("warcard_2", _qty);
            _p.wish_count++;
            break;

        case "3星强化用卡":
            add_material_amount("warcard_3", _qty);
            _p.wish_count++;
            break;

        case "4星强化用卡":
            add_material_amount("warcard_4", _qty);
            _p.wish_count++;
            break;

        case "初级强化水晶":
            add_material_amount("less_crystal", _qty);
            _p.wish_count++;
            break;

        case "中级强化水晶":
            add_material_amount("middle_crystal", _qty);
            _p.wish_count++;
            break;

        case "3级四叶草":
            add_material_amount("clover_3", _qty);
            _p.wish_count++;
            break;

        case "4级四叶草":
            add_material_amount("clover_4", _qty);
            if (_is_pity)
            {
                _p.wish_count = 0;
                _p.pity_count++;
            }
            else
                _p.wish_count++;
            break;

        case "高级强化水晶":
            add_material_amount("advanced_crystal", _qty);
            if (_is_pity)
            {
                _p.wish_count = 0;
                _p.pity_count++;
            }
            else
                _p.wish_count++;
            break;
    }
}

function gods_hall_get_guarantee_reward()
{
    // 2026-10-27：抽卡模式与普通模式同一套保底，不再单独走「只出四叶草/水晶」分支
    if (global.save_data.player.pity_count % 2 == 0)
    {
        var r = irandom(99);
        if (r < 60)
            return ["4级四叶草", 5];
        else if (r < 80)
            return ["高级强化水晶", 100];
        else
        {
            var r2 = irandom(99);
            if (r2 < 60)
                return ["神谕之石", 5];
            else if (r2 < 80)
                return ["神谕之石", 10];
            else
                return ["神谕之石", 25];
        }
    }
    else
    {
        var r = irandom(99);
        if (r < 60)
            return ["神谕之石", 5];
        else if (r < 80)
            return ["神谕之石", 10];
        else
            return ["神谕之石", 25];
    }
}
