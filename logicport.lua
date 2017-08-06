
-- Create new protocol
local logicport_bulk = Proto("logicport_bulk", "Intronix LogicPort USB protocol")

-- Import FTDI FT245BL specific stuff
dofile("plugins/logicport/ft245_modemstatus.lua")

local command_types =
{
    [0xc1] = "C1",
    [0xc2] = "C2",
    [0xc3] = "C3"
}

local field_command_type = ProtoField.uint8(
    "logicport_bulk.command_type",
    "Command type",
    base.HEX,
    command_types
)

local field_sequence_number = ProtoField.uint16(
    "logicport_bulk.sequence_number",
    "Sequence number",
    base.HEX
)

logicport_bulk.fields =
{
    field_modem_status,
    field_command_type,
    field_sequence_number
}

local usb_packet_length_field = Field.new("usb.urb_len")
local usb_direction_field = Field.new("usb.bmRequestType.direction")

--
-- This function dissects the
-- USB bulk traffic to and from the LogicPort
--
function logicport_bulk.dissector(buffer, pinfo, tree)

    local USB_BULK = 0x03
    local DIRECTION_OUT = 0
    local DIRECTION_IN  = 1
    local LOGICPORT_ENDPOINT_OUT = 0x02
    local LOGICPORT_ENDPOINT_IN  = 0x81

    -- beginning of communication data
    local payload_offset = 27

    --usb.bmAttributes.transfer == USB_BULK
    --usb.bmRequestType.direction == DIRECTION_OUT
    --usb.bmRequestType.recipient == LOGICPORT_ENDPOINT_OUT

    local usb_direction = usb_direction_field()
    local packet_length = usb_packet_length_field()

    --if usb_direction == DIRECTION_IN
    --then
        local subtree = tree:add(logicport_bulk, buffer(payload_offset, 2))
        subtree:add(field_modem_status, buffer(payload_offset, 2))

        --if packet_length <= 2 then return end

        subtree:add(field_command_type, buffer(payload_offset+2, 1))

        --if packet_length <= 3 then return end

        subtree:add(field_sequence_number, buffer(payload_offset+3, 2))
    --end
end

--local usb_bulk_dissector = DissectorTable.get("usb.bulk")

-- Check for a match in the field interface class
--usb_bulk_dissector:add(0xffff, logicport_bulk);

register_postdissector(logicport_bulk)
