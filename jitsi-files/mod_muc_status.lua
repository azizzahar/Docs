-- Prosody IM
-- Copyright (C) 2017 Atlassian
--

local jid = require "util.jid";
local it = require "util.iterators";
local json = require "util.json";
local iterators = require "util.iterators";
local array = require"util.array";

local have_async = pcall(require, "util.async");
if not have_async then
    module:log("error", "requires a version of Prosody with util.async");
    return;
end

local async_handler_wrapper = module:require "util".async_handler_wrapper;

local tostring = tostring;
local neturl = require "net.url";
local parse = neturl.parseQuery;

-- option to enable/disable room API token verifications
local enableTokenVerification
    = module:get_option_boolean("enable_roomsize_token_verification", false);

local token_util = module:require "token/util".new(module);
local get_room_from_jid = module:require "util".get_room_from_jid;

-- no token configuration but required
if token_util == nil and enableTokenVerification then
    log("error", "no token configuration but it is required");
    return;
end

-- required parameter for custom muc component prefix,
-- defaults to "conference"
local muc_domain_prefix
    = module:get_option_string("muc_mapper_domain_prefix", "conference");

--- Verifies room name, domain name with the values in the token
-- @param token the token we received
-- @param room_address the full room address jid
-- @return true if values are ok or false otherwise
function verify_token(token, room_address)


    if not enableTokenVerification then
        return true;
    end

    -- if enableTokenVerification is enabled and we do not have token
    -- stop here, cause the main virtual host can have guest access enabled
    -- (allowEmptyToken = true) and we will allow access to rooms info without
    -- a token
    if token == nil then
        log("warn", "no token provided");
        return false;
    end

    local session = {};
    session.auth_token = token;
    local verified, reason = token_util:process_and_verify_token(session);
    if not verified then
        log("warn", "not a valid token %s", tostring(reason));
        return false;
    end

    if not token_util:verify_room(session, room_address) then
        log("warn", "Token %s not allowed to join: %s",
            tostring(token), tostring(room_address));
        return false;
    end

    return true;
end



-- Get full list from "all_rooms", then iterate to get each room details 
function get_all(event)

        if (not event.request.url.query) then
                return { status_code = 400; };
        end

        local params = parse(event.request.url.query);
        local domain_name = params["domain"];
--        local subdomain = params["subdomain"];

        local host=muc_domain_prefix.."."..domain_name

        local component = hosts[host];

        local allrooms=array() -- store the result of all_rooms()
        local state=array() -- store the final json

        if component then
                local muc = component.modules.muc
                if muc and rawget(muc,"all_rooms") then
                        allrooms= muc.all_rooms();
                end
        end

        -- iterate the rooms
        for room in allrooms  do

                        local room_jid = room.jid;
                        local getroomstate=get_room(room_jid) -- use de get_room() below 
                        state:push({getroomstate})
        end


        return { status_code = 200; body = json.encode(state) };

end



-- get all room details by the get_room_from_jid() util function
function get_room (room_address)


        local room_name,domain_name=jid.split(room_address) -- split to get readable var

        local room = get_room_from_jid(room_address); -- get it

        local participant_count = 0; -- how many
        local audiomuted_count = 0; -- how many muted 
        local videomuted_count = 0; -- how many video muted

        local occupants_json = array(); -- store the occupant list & details
        local room_json = array(); -- store the room details

        if room then
                
                local occupants = room._occupants;  --_occupants is an object of room 
                
                if occupants then
                    for _, occupant in room:each_occupant() do
                        
                        -- filter focus as we keep it as hidden participant
                        if string.sub(occupant.nick,-string.len("/focus"))~="/focus" then

                            for _, pr in occupant:each_session() do

                                local nick = pr:get_child_text("nick", "http://jabber.org/protocol/nick") or "";
                                local audiomuted = pr:get_child_text("audiomuted", "http://jitsi.org/jitmeet/audio") or "";
                                local videomuted = pr:get_child_text("videomuted", "http://jitsi.org/jitmeet/video") or "";
                --              local email = pr:get_child_text("email") or "";  -- GRPD PRIVACY PROBLEMATICS

                                occupants_json:push({
                                    jid = tostring(occupant.nick),
                --                  email = tostring(email), -- GRPD PRIVACY PROBLEMATICS
                                    display_name = tostring(nick),
                                    role = tostring(occupant.role),
                                    audiomuted = tostring(audiomuted),
                                    videomuted = tostring(videomuted)});

                                -- just count 
                                participant_count=participant_count+1


                                if audiomuted=="true"  then    -- yep its not a real boolean :)
                                        audiomuted_count=audiomuted_count+1
                                end

                                if videomuted=="true"  then
                                        videomuted_count=videomuted_count+1
								end

                            end
                        end
                    end
    			end

                --- Build the room json

                -- TODO : the above commented line fail because its not the good node
--              local createdms=room:get_child_text("created-ms", "http://jabber.org/protocol/focus") or "";

				-- Build de final json
                room_json:push({
                        roomjid=tostring(room_address),
                        roomname=tostring(room_name),
                        domain=tostring(domain_name),
--                      created=tostring(createdms),
                        NBparticipant=tostring(participant_count),
                        NBaudiomuted=tostring(audiomuted_count),
                        NBvideomuted=tostring(videomuted_count),
                        participant=occupants_json})  -- add the occupant json
        end
        

    return room_json

end;


-- get the full status by .....:5280/status
function module.load()
    module:depends("http");
        module:provides("http", {
                default_path = "/";
                route = {
                        ["GET status"] = function (event) return async_handler_wrapper(event,get_all) end;
                        ["GET sessions"] = function () return tostring(it.count(it.keys(prosody.full_sessions))); end;
                };
        });
end
