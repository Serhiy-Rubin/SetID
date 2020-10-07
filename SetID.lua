script_name("SetID")
script_author("Serhiy_Rubin")
script_version("07/10/2020")
local sampev = require 'lib.samp.events'
local timeconnect = 0
local ffi = require("ffi")
ffi.cdef [[ bool SetCursorPos(int X, int Y); ]]
local user32 = ffi.load("user32")   -- Load User32 DLL handle
ffi.cdef([[
enum{
    MB_OK = 0x00000000L,
    MB_ICONINFORMATION = 0x00000040L
};

typedef void* HANDLE;
typedef HANDLE HWND;
typedef const char* LPCSTR;
typedef unsigned UINT;

int MessageBoxA(HWND, LPCSTR, LPCSTR, UINT);
]])
ffi.cdef [[
    typedef int BOOL;
    typedef unsigned long HANDLE;
    typedef HANDLE HWND;
    typedef int bInvert;
    HWND GetActiveWindow(void);

    BOOL FlashWindow(HWND hWnd, BOOL bInvert);

    HWND GetForegroundWindow();
]]

local setid, id1, id2 = false, 0, 0

function main()
	if not isSampLoaded() or not isSampfuncsLoaded() then return end
	while not isSampAvailable() do wait(100) end
	sampRegisterChatCommand('setid', function(param)
		if not setid then
			if param:find('(%d+) (%d+)') then
				setid = true
				WorkInBackground(true)
				if setid then
					local S1, S2 = param:match('(%d+) (%d+)')
					id1 = tonumber(S1) ; id2 = tonumber(S2)
					local _, my_id = sampGetPlayerIdByCharHandle(PLAYER_PED)
					for i = id1, id2 do
						if i == my_id then
							setid = false
							WorkInBackground(false)
							sampAddChatMessage('У вас уже ID: '..i..'. Поиск отключен.', -1)
						end
					end
					if setid then reconnect() end
					return
				end
			end
		else
			setid = false
			WorkInBackground(false)
			sampAddChatMessage('Поиск ID отключен', -1)
			return
		end
		sampAddChatMessage(' /setid [0-999] [0-999] - Укажите диапазон поиска ID', -1)
	end)

	while true do
		wait(0)
        if setid then 
        	local chatstring = sampGetChatString(99)
        	if chatstring == "Server closed the connection." then reconnect() end
        	if chatstring == "You are banned from this server." then reconnect() end
        	if chatstring == 'The server is restarting..' then reconnect() end
        end
	end
end

function reconnect()
	if (os.time() - timeconnect) > 16 then
		sampAddChatMessage('Запущен поиск ID в диапазоне от '..id1..' до '..id2, -1)
		lua_thread.create(function()
			sampDisconnectWithReason(false)
			timeconnect = os.time()
			wait(15500)
			sampSetGamestate(1)
		end)
	end
end

function sampev.onInitGame(playerId, hostName, settings, vehicleModels, unknown)
	lua_thread.create(function(playerId)
		for i = id1, id2 do
			if i == playerId then
				setid = false
				sampAddChatMessage('Получен ID: '..i..'. Поиск отключен.', -1)
				isAFK_Message('Получен ID: '..i..'. Поиск отключен.')
				WorkInBackground(false)
				if ffi.C.GetActiveWindow() ~= nil then
					lua_thread.create(function()
			        	repeat wait(0) until sampIsCursorActive()
						local X, Y = convertGameScreenCoordsToWindowScreenCoords(317.65740966797, 404.25)
						ffi.C.SetCursorPos(X, Y)
						setVirtualKeyDown(1, true)
						setVirtualKeyDown(1, false)
					end)
				end
			end
		end
		if setid then sampAddChatMessage('Получен ID: '..playerId..'. Ищем дальше.', -1) ; reconnect() end
	end, playerId)
end

function isAFK_Message(text)
	if ffi.C.GetActiveWindow() == nil then
		user32.MessageBoxA(nil, text, "SetID", 0x00010000)
	end
end

function WorkInBackground(work)
    local memory = require 'memory'
    if work then -- on
        memory.setuint8(7634870, 1) 
        memory.setuint8(7635034, 1)
        memory.fill(7623723, 144, 8)
        memory.fill(5499528, 144, 6)
        memory.fill(0x00531155, 0x90, 5, true)
    else -- off
        memory.setuint8(7634870, 0)
        memory.setuint8(7635034, 0)
        memory.hex2bin('5051FF1500838500', 7623723, 8)
        memory.hex2bin('0F847B010000', 5499528, 6)
    end 
end