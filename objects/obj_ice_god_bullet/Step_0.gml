if (global.is_paused)
{
    image_speed = 0;
    exit;
}

image_speed = 1;
y += move_speed;

if (y >= target_y)
{
    if (instance_exists(target_instance))
    {
        hitted_enemy = target_instance;
        with (target_instance)
        {
            audio_play_sound(snd_ice_god, 0, 0);
            damage_amount = other.damage;
            damage_type = other.damage_type;
            event_user(0);

            // 减速：只有三转 / 四转有，2.5 秒（表 9.追踪 r77「三转减速2.5s」；终转移除减速）
            if (other.shape >= 1 && other.shape <= 2 && ice_timer < 150)
                ice_timer = 150;

            hit_enemy = true;
        }
    }

    instance_destroy();
}
