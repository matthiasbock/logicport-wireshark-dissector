
-- Create new protocol
local logicport_bulk = Proto("logicport_bulk", "Intronix LogicPort USB protocol")

-- Import FTDI FT245BL specific stuff
dofile("plugins/logicport/ft245_modemstatus.lua")
dofile("plugins/logicport/ft245_control.lua")
dofile("plugins/logicport/ft245_baudrates.lua")

local preamble_types =
{
    [0xc1] = "C1",
    [0xc2] = "C2",
    [0xc3] = "C3"
}

local field_preamble_type = ProtoField.uint8(
    "logicport_bulk.preamble_type",
    "Preamble type",
    base.HEX,
    preamble_types
)

local field_packet_number = ProtoField.uint16(
    "logicport_bulk.packet_number",
    "Packet number",
    base.HEX
)

local field_request_type = ProtoField.uint16(
    "logicport_bulk.request_type",
    "Request type",
    base.HEX
)

local field_expected_response_size = ProtoField.uint16(
    "logicport_bulk.expected_response_size",
    "Expected response size",
    base.HEX
)

local field_response = ProtoField.none(
    "logicport_bulk.response",
    "Response",
    base.HEX
)

logicport_bulk.fields =
{
    field_modem_status,
    field_preamble_type,
    field_packet_number,
    field_request_type,
    field_expected_response_size,
    field_response
}

local usb_packet_data_length_field = Field.new("usb.urb_len")
local usb_direction_field = Field.new("usb.bmRequestType.direction")

function buffer_to_uint32(buffer)
    return  buffer(0,1):uint() +
            bit.lshift(buffer(1,1):uint(), 8) +
            bit.lshift(buffer(2,1):uint(), 16) +
            bit.lshift(buffer(3,1):uint(), 24)
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

    local LOGICPORT_ENDPOINT_OUT = 0x02
    local LOGICPORT_ENDPOINT_IN  = 0x81

    -- beginning of communication data
    local payload_offset = 27

    local usb_direction = bit.band(buffer(21,1):uint(), 0x80)
    local packet_data_length = buffer_to_uint32(buffer(23,4))

    local bmAttributes_transfer = buffer(22,1):uint()

    if bmAttributes_transfer == USB_TRANSFER_TYPE_CONTROL
    then
        bmRequestType = buffer(28,1):uint()
        bRequest = buffer(29,1):uint()

        wValue = bit.lshift(buffer(31,1):uint(), 8) + buffer(30,1):uint()
        wValue_high = buffer(31,1):uint()
        wValue_low  = buffer(30,1):uint()

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

                if wValue == FTDI_BAUD_460800
                then
                    append_to_title(pinfo, ":460800bps")
                end
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

                append_to_title(pinfo, ":"..wValue_low.."ms")
            end

            if bRequest == FTDI_SET_BIT_MODE
            then
                append_to_title(pinfo, ", FTDI_SET_BIT_MODE")

                if wValue_high == 0x00 then append_to_title(pinfo, ":USB to parallel FIFO") end
                if wValue_high == 0x01
                then
                    append_to_title(pinfo, ":asynchronous bitbang")

                    if bit.band(wValue_low, 0x01) > 0 then append_to_title(pinfo, ",D0:out") else append_to_title(pinfo, ",D0:in") end
                    if bit.band(wValue_low, 0x02) > 0 then append_to_title(pinfo, ",D1:out") else append_to_title(pinfo, ",D1:in") end
                    if bit.band(wValue_low, 0x04) > 0 then append_to_title(pinfo, ",D2:out") else append_to_title(pinfo, ",D2:in") end
                    if bit.band(wValue_low, 0x08) > 0 then append_to_title(pinfo, ",D3:out") else append_to_title(pinfo, ",D3:in") end
                    if bit.band(wValue_low, 0x10) > 0 then append_to_title(pinfo, ",D4:out") else append_to_title(pinfo, ",D4:in") end
                    if bit.band(wValue_low, 0x20) > 0 then append_to_title(pinfo, ",D5:out") else append_to_title(pinfo, ",D5:in") end
                    if bit.band(wValue_low, 0x40) > 0 then append_to_title(pinfo, ",D6:out") else append_to_title(pinfo, ",D6:in") end
                    if bit.band(wValue_low, 0x80) > 0 then append_to_title(pinfo, ",D7:out") else append_to_title(pinfo, ",D7:in") end
                end
                if wValue_high == 0x02 then append_to_title(pinfo, ":MPSSE") end
                if wValue_high == 0x04 then append_to_title(pinfo, ":synchronous bitbang") end
                if wValue_high == 0x08 then append_to_title(pinfo, ":MCU host bus emulation") end
                if wValue_high == 0x10 then append_to_title(pinfo, ":fast serial") end
                if wValue_high == 0x20 then append_to_title(pinfo, ":CBUS bitbang") end
                if wValue_high == 0x40 then append_to_title(pinfo, ":synchronous FIFO") end
                if wValue_high == 0x80 then append_to_title(pinfo, ":FT1284") end
            end
        end

        -- Device to host
        if bmRequestType == 0xC0
        then
            if bRequest == 0x90
            then
                append_to_title(pinfo, ", SIO_READ_EEPROM_REQUEST")
            end

            if bRequest == FTDI_GET_MODEM_STATUS
            then
                append_to_title(pinfo, ", FTDI_GET_MODEM_STATUS")
            end

            if bRequest == FTDI_GET_LATENCY_TIMER
            then
                append_to_title(pinfo, ", FTDI_GET_LATENCY_TIMER")
            end

            if bRequest == FTDI_GET_BIT_MODE
            then
                append_to_title(pinfo, ", FTDI_GET_BIT_MODE")
            end
        end
    end

    if bmAttributes_transfer == USB_TRANSFER_TYPE_BULK
    then
        if usb_direction == DIRECTION_OUT
        then
            if packet_data_length == 0
            then
                append_to_title(pinfo, ", empty?")
                return
            end

            if packet_data_length < 3
            then
                append_to_title(pinfo, ", too short?")
                return
            end

            local subtree = tree:add(logicport_bulk, buffer(payload_offset, packet_data_length))

            -- Preamble byte
            local preamble_type = buffer(payload_offset, 1)
            subtree:add(field_preamble_type, preamble_type)

            -- Packet number
--            local packet_number = buffer(payload_offset+1, 2)
--            subtree:add(field_packet_number, packet_number)
--            append_to_title(pinfo, ", "..packet_number)

            -- Request type
            local request_type = bit.lshift(buffer(payload_offset+2, 1):uint(), 8) + buffer(payload_offset+1, 1):uint()
            subtree:add(field_request_type, request_type)
            append_to_title(pinfo, ", type:"..request_type)

            if packet_data_length < 5
            then
                -- This is not an error
                return
            end

            -- Expected response size
            local expected_response_size = bit.lshift(buffer(payload_offset+4, 1):uint(), 8) + buffer(payload_offset+3, 1):uint()
            subtree:add(field_expected_response_size, expected_response_size)
            append_to_title(pinfo, ", expects:"..expected_response_size)
        else
            local subtree = tree:add(logicport_bulk, buffer(payload_offset, packet_data_length))

            -- FTDI modem status bytes
            local modem_status = buffer(payload_offset, 2)
            subtree:add(field_modem_status, modem_status)

            -- Parse FTDI modem status bits
            --local subtree = tree:add(logicport_bulk, buffer(payload_offset, 2))
            --subtree:add(field_modem_status, buffer(payload_offset, 2))

            if packet_data_length <= 2
            then
                append_to_title(pinfo, ", empty?")
                return
            end

            -- Preamble byte
            subtree:add(field_preamble_type, buffer(payload_offset+2, 1))

            if packet_data_length <= 3 then return end

            -- Packet number
            local packet_number = buffer(payload_offset+3, 2)
            subtree:add(field_packet_number, packet_number)
            append_to_title(pinfo, " #0x"..packet_number)

            if packet_data_length <= 5 then return end

            local extra_bytes = packet_data_length - 5
            append_to_title(pinfo, ", given:"..extra_bytes)
            local response = buffer(payload_offset+5, extra_bytes)
            subtree:add(field_response, response)
        end
    end
end

--local usb_bulk_dissector = DissectorTable.get("usb.bulk")

-- Check for a match in the field interface class
--usb_bulk_dissector:add(0xffff, logicport_bulk);

register_postdissector(logicport_bulk)
