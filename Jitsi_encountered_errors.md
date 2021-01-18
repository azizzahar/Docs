ERROR 1:

http.server	error	Traceback[httpserver]: /usr/lib/prosody/util/stanza.lua:62: invalid text value: expected string, got number
|| 
mod_bosh	error	Traceback[bosh]: /usr/lib/prosody/util/stanza.lua:62: invalid text value: expected string, got number

Always says user alone in room 

=> editing stanza.lua file line 120 with:

function stanza_mt:text(text)
        if text ~= nil and text ~= "" then
                local last_add = self.last_add;
HERE-->         (last_add and last_add[#last_add] or self):add_direct_child(tostring(text));
        end
        return self;
        
ref: https://community.jitsi.org/t/error-traceback-bosh-usr-lib-prosody-util-stanza-lua-invalid-text-value-expected-string-got-userdata/66439/2





ERROR 2:


