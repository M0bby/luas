local p_list_menu = menu.add_list("Alyx Admin Panel", "Player List ", {}, 20)


local convar_t = ffi.typeof([[
    struct {
        int pad1; //0x0000
        void* pNext; //0x0004 
        __int32 bRegistered; //0x0008 
        const char* pszName; //0x000C 
        const char* pszHelpString; //0x0010 
        int32_t nFlags; //0x0014 
        int pad2; //0x0018
        void* pParent; //0x001C 
        char* pszDefaultValue; //0x0020 
        char* strString; //0x0024 
        __int32 StringLength; //0x0028 
        float fValue; //0x002C 
        int32_t nValue; //0x0030 
        __int32 bHasMin; //0x0034 
        float fMinVal; //0x0038 
        __int32 bHasMax; //0x003C 
        float fMaxVal; //0x0040 
        void* fnChangeCallback; //0x0044 
        int pad3;
        int pad4;
        int iCallbackSize; //0x0050
    }]])

local cvar_interface = memory.create_interface("vstdlib.dll", "VEngineCvar007")
local cvar_interface_ptr = ffi.cast("void***",cvar_interface)
local find_cvar_vfunc = memory.get_vfunc(tonumber(ffi.cast("unsigned long", cvar_interface_ptr)), 15)
local find_cvar = ffi.cast(ffi.typeof("$*(__thiscall*)(void*,char*)", convar_t ), find_cvar_vfunc)
local name_cvar_struct = ffi.new(ffi.typeof("$[1]",convar_t))
local c_str = ffi.new("char[?]", #"name" + 1)
ffi.copy(c_str, "name")


local engine_client_interface = memory.create_interface("engine.dll","VEngineClient014")
local engine_client_ptr = ffi.cast("void***",engine_client_interface)
local get_player_from_id_vfunc = memory.get_vfunc(tonumber(ffi.cast("unsigned long",engine_client_ptr)),9)
local get_player_from_id = ffi.cast(ffi.typeof("int(__thiscall*)(void*,int)"),get_player_from_id_vfunc)

local p_selected = 0
local p_count = 0
local p_list = {}
local list_to_player = {}
local original_name = cvars.name:get_string()
local p_list_clansteal_index = 0
local p_list_clansteal_enabled = false

local function set_name(name)
    local name_cvar_struct = ffi.new(ffi.typeof("$[1]",convar_t))
    local c_str = ffi.new("char[?]", #"name" + 1)
    ffi.copy(c_str, "name")
    local name_cvar = find_cvar(cvar_interface_ptr, c_str)
    name_cvar[0].iCallbackSize = 0
    cvars.name:set_string(name)
end

local function p_list_callback(event)

    if not engine.is_in_game() then return end
    if event.name ~= "player_spawned" and event.name ~= "round_start" and event.name ~= "fuck_you" then return end
    local index = 1
    local user_id = 0
    local user_id_table = {}
    local i = 0
    while i < 1000 do
        user_id_table[get_player_from_id( engine_client_ptr, i)] = i
        i = i + 1
    end
    local names = {}
    for _, player in pairs(entity_list.get_players()) do

        local p_list_item = {
            name = tostring(player:get_name()),
            index = player:get_index(),
            user_id = user_id_table[player:get_index()],
            bot = player:has_player_flag(e_player_flags.FAKE_CLIENT),
        }
        p_list[player:get_index()] = p_list_item
        if player:has_player_flag(e_player_flags.FAKE_CLIENT) then
            names[index] = "BOT " .. p_list_item.name
        elseif player:get_name() == "GOTV" then
            names[index] = ""
        else
            names[index] = p_list_item.name
        end
        list_to_player[index] = player:get_index()
        index = index + 1
    end


    p_selected = p_list_menu:get()
    p_list_menu:set_items(names)
end

local p_list_refresh = menu.add_button("Alyx Admin Panel 2", "Refresh list", function ()
     p_list_callback({name = "fuck_you"})
end)

p_list_callback({name = "fuck_you"})

local function apply_p(ctx, cmd, unpredicted_data)
    for _, player in pairs(p_list) do
        if player.friendly then 
            ctx:ignore_target(player.index)
        end

        if player.priority_enabled then
            ctx:prioritize_target(player.index, player.priority_level)
        end
    end


end

local gagresone = menu.add_list('Alyx Admin Panel 2', "Reasone", {"Killsay", "Staff TT", "Chat Spam", "Music on Voice", "Voice Chat Spamming", "Test"}, 6)
local banresone = menu.add_text_input('Alyx Admin Panel 2', 'Ban Reason')
local time = menu.add_slider('Alyx Admin Panel 2', 'Time', 0, 60)
local weapons = menu.add_selection('Alyx Admin Panel 2', 'Weapons', {"Awp", "Auto"})
local kickresone = menu.add_text_input('Alyx Admin Panel 2', 'Kick Reason')

local format = function(str, ...)
    return str:format(unpack({...}))
end

local kick = menu.add_button('Alyx Admin Panel 3', 'Kick', function()
    engine.execute_cmd(format("sm_kick #%s %s", tostring(p_list[list_to_player[p_list_menu:get()]].user_id), kickresone:get()))
end)

local slap = menu.add_button('Alyx Admin Panel 3', 'Slap', function()
    engine.execute_cmd("sm_slap #" .. tostring(p_list[list_to_player[p_list_menu:get()]].user_id))
end)

local slay = menu.add_button('Alyx Admin Panel 3', 'Slay', function()
    engine.execute_cmd("sm_slay #" .. tostring(p_list[list_to_player[p_list_menu:get()]].user_id))
end)

local gag = menu.add_button('Alyx Admin Panel 3', 'Gag', function()
    engine.execute_cmd(format("sm_gag #%s %s", tostring(p_list[list_to_player[p_list_menu:get()]].user_id), time:get(), gagresone:get_items()[gagresone:get()]))
end)

local ban = menu.add_button('Alyx Admin Panel 3', 'Ban', function()
    engine.execute_cmd(format("sm_ban #%s %s", tostring(p_list[list_to_player[p_list_menu:get()]].user_id), time:get(), banresone:get()))
end)

local restrict = menu.add_button('Alyx Admin Panel 3', 'Restrict', function()
    engine.execute_cmd(format("sm_restrict %s %s", weapons:get_items()[weapons:get()], "0", "both"))
end)

local unrestrict = menu.add_button('Alyx Admin Panel 3', 'UnRestrict', function()
    engine.execute_cmd(format("sm_unrestrict %s %s", weapons:get_items()[weapons:get()], "0", "both"))
end)

menu.set_group_column('Alyx Admin Panel', 1)
menu.set_group_column('Alyx Admin Panel 2 ', 2)
menu.set_group_column('Alyx Admin Panel 3', 3)

callbacks.add(e_callbacks.EVENT, function()
end)