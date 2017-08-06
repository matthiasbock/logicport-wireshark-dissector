
-- Create new protocol object
local logicport_bulk = Proto("logicport_bulk", "Intronix LogicPort USB protocol")

local field_modem_status = ProtoField.uint16(
    "logicport_bulk.modemstatus",
    "logicport_bulk.modemstatus",
    ftypes.UINT16,
    { [0] = "unknown" },
    base.HEX,
    "The FT245BL's modem status bytes"
)

logicport_bulk.fields =
{
    field_modem_status
}

--
-- This function dissects the
-- USB bulk traffic to and from the LogicPort
--
function logicport_bulk.dissector(buf, pkt, tree)

    local USB_BULK = 0x03
    local DIRECTION_OUT = 0x00
    local LOGICPORT_ENDPOINT_OUT = 0x02

    --usb.bmAttributes.transfer == USB_BULK
    --usb.bmRequestType.direction == DIRECTION_OUT
    --usb.bmRequestType.recipient == LOGICPORT_ENDPOINT_OUT

    local subtree = tree:add(logicport_bulk, buf(0,2))
    subtree:add(field_modem_status, buf(0,2))

end

local usb_bulk_dissector = DissectorTable.get("usb.bulk")
usb_bulk_dissector:add(0xffff, logicport_bulk);
