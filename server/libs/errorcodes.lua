local error = {}

error.code = {
    SUCCESS = 0,
    FAILED = 1,
    HANDSHAKE_ERROR = 2,
    OPER_TOO_FAST = 3,
    INVALID_REGISTERINFO = 4,
    ILLEGAL_REGISTER = 5,
    INVALID_VERIFYCODE = 6,
    EXECUTE_DB_SCRIPT_ERROR = 7,
}

error.reason = {
    [error.code.SUCCESS] = '成功',
    [error.code.FAILED] = '失败',
    [error.code.HANDSHAKE_ERROR] = '客户端验证失败',
    [error.code.OPER_TOO_FAST] = '操作太快,请120秒后再试',
    [error.code.INVALID_REGISTERINFO] = '请提供正确的注册信息',
    [error.code.ILLEGAL_REGISTER] = '非法注册',
    [error.code.INVALID_VERIFYCODE] = '验证码不正确',
    [error.code.EXECUTE_DB_SCRIPT_ERROR] = '数据库脚本执行报错',

}


return error