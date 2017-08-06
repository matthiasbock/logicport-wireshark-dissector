
local mask_error_receiver_fifo = 0x8000
local value_error_receiver_fifo =
{
    [0x8000] = "Error",
    [0x0000] = "No error",
}

local field_error_receiver_fifo = ProtoField.uint16(
    "logicport_bulk.modemstatus.error_receiver_fifo",
    "Receiver FIFO status",
    ftypes.UINT16,
    value_error_receiver_fifo,
    base.HEX,
    mask_error_receiver_fifo
)

field_modem_status = ProtoField.uint16(
    "logicport_bulk.modemstatus",
    "Modem status",
    ftypes.UINT16,
    nil,
    base.HEX
)

-- TODO: All the other bit values
