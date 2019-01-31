local card = require "cards"

local logic = {}

logic.stage = {
    START = 1,          --游戏开始
    ELECTION = 2,       --选庄
    BETTING = 3,        --下注
    SENDCARD = 4,       --发牌
    COMBINATION = 5,    --拼牌
    COMPARE = 6,        --比牌
    BONUS = 7,          --结算
    STOP = 8,
}

logic.expires = {
    [logic.stage.START] = 3,
    [logic.stage.ELECTION] = 4,
    [logic.stage.BETTING] = 4,
    [logic.stage.SENDCARD] = 3,
    [logic.stage.COMBINATION] = 6,
    [logic.stage.COMPARE] = 6,
    [logic.stage.BONUS] = 3,
    [logic.stage.STOP] = 5,
}

return logic