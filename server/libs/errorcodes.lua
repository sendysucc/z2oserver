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
    PHONE_ALREADY_USED = 8,
    PASSWORD_NOT_ALLOWED = 9,
    PHONE_NUMBER_NOT_MATCHED = 10,
    PHONE_NOT_EXISTS = 11,
    PASSWORD_MISS = 12,
    ACCOUNT_FORBIDDEN = 13,
    LOGIN_INFO_ERR = 14,
    PLAYER_BREAKLINE = 15,
    ALREADY_LOGIN = 16,
    NO_GAME_AVAILABLE = 17,
    NO_ROOM_AVAILABLE = 18,

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
    [error.code.PHONE_ALREADY_USED] = '手机号码已经被注册',
    [error.code.PASSWORD_NOT_ALLOWED] = '密码不符合要求,请重新设置',
    [error.code.PHONE_NUMBER_NOT_MATCHED] = '手机与验证码不匹配',
    [error.code.PHONE_NOT_EXISTS] = '账号不存在',
    [error.code.PASSWORD_MISS] = '密码错误',
    [error.code.ACCOUNT_FORBIDDEN] = '账户被禁用',
    [error.code.LOGIN_INFO_ERR] = '请提供账户和密码',
    [error.code.PLAYER_BREAKLINE] = '玩家短线重新登录',
    [error.code.ALREADY_LOGIN] = '账号已经登录',
    [error.code.NO_GAME_AVAILABLE] = '没有游戏',
    [error.code.NO_ROOM_AVAILABLE] = '没有房间',


}


return error