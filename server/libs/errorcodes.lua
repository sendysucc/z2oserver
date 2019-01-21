local error = {}

error.code = {
    SUCCESS = 0,
    FAILED = 1,
    HANDSHAKEERROR = 2,
    OPERTOOFAST = 3,
}

error.reason = {
    [error.code.SUCCESS] = '成功',
    [error.code.FAILED] = '失败',
    [error.code.HANDSHAKEERROR] = '客户端验证失败',
    [error.code.OPERTOOFAST] = '操作太快,请120秒后再试',
}


return error