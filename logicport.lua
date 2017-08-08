
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

function buffer_to_uint32(buffer)
    return buffer(0,4):uint()
end

function append_to_title(pinfo, text)
    pinfo.cols.info:set(tostring(pinfo.cols.info)..text)
end

--
-- This function dissects the
-- USB bulk traffic to and from the LogicPort
--
function logicport_bulk.dissector(buffer, pinfo, tree)

    local USB_TRANSFER_TYPE_CONTROL = 0x02
    local USB_TRANSFER_TYPE_BULK = 0x03

    local DIRECTION_OUT = 0x00
    local DIRECTION_IN  = 0x80

    local FTDI_RESET = 0x00
    local FTDI_MODEM_CTRL = 0x01
    local FTDI_SET_FLOW_CTRL = 0x02
    local FTDI_SET_BAUD_RATE = 0x03
    local FTDI_SET_DATA = 0x04
    local FTDI_GET_MODEM_STATUS = 0x05
    local FTDI_SET_EVENT_CHAR = 0x06
    local FTDI_SET_ERROR_CHAR = 0x07
    local FTDI_SET_LATENCY_TIMER = 0x09
    local FTDI_GET_LATENCY_TIMER = 0x0A
    local FTDI_SET_BIT_MODE = 0x0B
    local FTDI_GET_BIT_MODE = 0x0C

    local LOGICPORT_ENDPOINT_OUT = 0x02
    local LOGICPORT_ENDPOINT_IN  = 0x81

    -- beginning of communication data
    local payload_offset = 27

    local usb_direction = bit.band(buffer(21,1):uint(), 0x80)
    local packet_length = buffer_to_uint32(buffer(23,4))

    local bmAttributes_transfer = buffer(22,1):uint()

    if bmAttributes_transfer == USB_TRANSFER_TYPE_CONTROL
    then
        bmRequestType = buffer(28,1):uint()
        bRequest = buffer(29,1):uint()

        -- Host to device
        if bmRequestType == 0x40
        then
            if bRequest == FTDI_RESET
            then
                append_to_title(pinfo, ", FTDI_RESET")
            end

            if bRequest == FTDI_MODEM_CTRL
            then
                append_to_title(pinfo, ", FTDI_MODEM_CTRL")
            end

            if bRequest == FTDI_SET_FLOW_CTRL
            then
                append_to_title(pinfo, ", FTDI_SET_FLOW_CTRL")
            end

            if bRequest == FTDI_SET_BAUD_RATE
            then
                append_to_title(pinfo, ", FTDI_SET_BAUD_RATE")
            end

            if bRequest == FTDI_SET_DATA
            then
                append_to_title(pinfo, ", FTDI_SET_DATA")
            end

            if bRequest == FTDI_SET_EVENT_CHAR
            then
                append_to_title(pinfo, ", FTDI_SET_EVENT_CHAR")
            end

            if bRequest == FTDI_SET_ERROR_CHAR
            then
                append_to_title(pinfo, ", FTDI_SET_ERROR_CHAR")
            end

            if bRequest == FTDI_SET_LATENCY_TIMER
            then
                append_to_title(pinfo, ", FTDI_SET_LATENCY_TIMER")
            end

            if bRequest == FTDI_SET_BIT_MODE
            then
                append_to_title(pinfo, ", FTDI_SET_BIT_MODE")

                wValue_high = buffer(31,1):uint()
                wValue_low  = buffer(30,1):uint()

                if wValue_high == 0x00 then append_to_title(pinfo, ":no function(?)") end
                if wValue_high == 0x01
                then
                    append_to_title(pinfo, ":asynchronous bitbanging")

                    if bit.band(wValue_low, 0x01) then append_to_title(pinfo, ",D0:out") else append_to_title(pinfo, ",D0:in") end
                end
                if wValue_high == 0x02 then append_to_title(pinfo, ":MPSSE") end
                if wValue_high == 0x04 then append_to_title(pinfo, ":synchronous bitbanging") end
                if wValue_high == 0x08 then append_to_title(pinfo, ":CPU emulation") end
                if wValue_high == 0x10 then append_to_title(pinfo, ":fast serial") end
                if wValue_high == 0x20 then append_to_title(pinfo, ":CBUS bitbanging") end
                if wValue_high == 0x40 then append_to_title(pinfo, ":undefined(?)") end
                if wValue_high == 0x80 then append_to_title(pinfo, ":undefined(?)") end
            end

            if bRequest == FTDI_GET_BIT_MODE
            then
                append_to_title(pinfo, ", FTDI_GET_BIT_MODE")
            end
        end

        -- Device to host
        if bmRequestType == 0xC0
        then
            if bRequest == FTDI_GET_MODEM_STATUS
            then
                append_to_title(pinfo, ", FTDI_GET_MODEM_STATUS")
            end

            if bRequest == FTDI_GET_LATENCY_TIMER
            then
                append_to_title(pinfo, ", FTDI_GET_LATENCY_TIMER")
            end
        end
    end

    if bmAttributes_transfer == USB_TRANSFER_TYPE_BULK
    then
        if usb_direction == DIRECTION_OUT
        then
            append_to_title(pinfo, ", OUT")

            if packet_length <= 0 then return end

        else
            append_to_title(pinfo, ", IN")

            if packet_length <= 0 then return end

            local subtree = tree:add(logicport_bulk, buffer(payload_offset, 2))

            subtree:add(field_modem_status, buffer(payload_offset, 2))

            if packet_length <= 2 then return end

            subtree:add(field_command_type, buffer(payload_offset+2, 1))

            if packet_length <= 3 then return end

            subtree:add(field_sequence_number, buffer(payload_offset+3, 2))
        end
    end
end

--local usb_bulk_dissector = DissectorTable.get("usb.bulk")

-- Check for a match in the field interface class
--usb_bulk_dissector:add(0xffff, logicport_bulk);

register_postdissector(logicport_bulk)
