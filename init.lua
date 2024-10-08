
local exports = {
	name = "configgenerator",
	version = "1.0.0",
	description = "Config Generator",
	author = { name = "Jake Wilson" }
}

local configgenerator = exports

function configgenerator.startplugin()

	emu.register_start(function()

		-- If no rom is loaded, don't do anything
		if emu.romname() == "___empty" then
			return
		end

		local inputs = ""
		local port_manager = manager.machine.ioport

		-- Iterate through all ports and their fields, generating input tags for .cfg output
		for portname, port in pairs(port_manager.ports) do
			for fieldname, field in pairs(port.fields) do
				local token = port_manager:input_type_to_token(field.type, field.player)

				-- Add to output only if it's a controller or misc type
				if (field.type_class == "controller" or field.type_class == 'misc' or field.type_class == 'dipswitch') then
					local comment = '\t\t\t<!-- ' .. field.name .. ' -->\n'

					inputs = inputs .. comment .. '\t\t\t<port tag="' .. portname .. '" type="' .. token .. '" mask="' .. field.mask .. '" defvalue="' .. field.defvalue

					-- If it's a dipswitch, add the current value
					if field.type_class == 'dipswitch' then
						inputs = inputs .. '" value="' .. field.user_value
					end

					inputs = inputs ..'"></port>\n\n'
				end
			end
		end

		-- .cfg header and footer
		local header = '<?xml version="1.0"?>\n<!-- This file is autogenerated; comments and unknown tags will be stripped -->\n<mameconfig version="10">\n\t<system name="mk2">\n\t\t<input>\n'
		local footer = '\t\t</input>\n\t</system>\n</mameconfig>\n'

		-- Get attributes of the output directory
		local path = "cfg_generated"
		local attr = lfs.attributes(path)

		-- Check if output directory already exists but is not a directory
		if (attr and attr.mode ~= "directory") then
			emu.print_verbose("configgenerator: output path exists but isn't directory " .. path)
			manager.machine.exit()
		end

		-- Path doesn't exist yet, create it
		if not attr then
			lfs.mkdir(path)

			-- Check that path was created
			if not lfs.attributes(path) then
				emu.print_verbose("configgenerator: unable to create path " .. path)
				manager.machine.exit()
			end
		end

		-- Write output file
		local file = io.open(path .. "/" .. emu.romname() .. ".cfg", "w")
		file:write(header .. inputs .. footer)
		file:close()

		-- manager.machine:exit()
	end)
end

return exports
