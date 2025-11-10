--- STEAMODDED HEADER
--- MOD_NAME:  Patolatro RPG
--- MOD_ID: PatolatroRPG
--- MOD_AUTHOR: [Abuu]
--- MOD_DESCRIPTION: Personagens dos nossos RPGs transformados em Balatro
--- PREFIX: rpgs
----------------------------------------------
------------MOD CODE -------------------------

if SMODS.Atlas then
  SMODS.Atlas({
    key = "modicon",
    path = "icon.png",
    px = 32,
    py = 32
  })
end


SMODS.Atlas{
    key = 'enhancements',
    path = 'enhancements.png',
    px = 71,
    py = 95
}

-- Carta fã
SMODS.Enhancement{
    key = 'carta_fa',
    atlas = 'enhancements',
    pos = { x = 0, y = 0 },
    
    loc_txt = {
        name = 'Carta Fã',
        text = {
            '{C:green}#1# em #4#{} chance de {C:mult}+#3#{} Mult',
            '{C:green}#2# em #6#{} chance de {C:money}$#5#{}',
        }
    },
    
    config = { extra = { mult = 15, dollars = 15, mult_odds = 3, dollars_odds = 10 } },

    
     loc_vars = function(self, info_queue, card)
        local mult_numerator, mult_denominator = SMODS.get_probability_vars(card, 1, card.ability.extra.mult_odds,
            'vremade_lucky_mult')
        local dollars_numerator, dollars_denominator = SMODS.get_probability_vars(card, 1,
            card.ability.extra.dollars_odds, 'vremade_lucky_money')
        return { vars = { mult_numerator, dollars_numerator, card.ability.extra.mult, mult_denominator, card.ability.extra.dollars, dollars_denominator } }
    end,
    calculate = function(self, card, context)
        if context.main_scoring and context.cardarea == G.play then
            local ret = {}
            if SMODS.pseudorandom_probability(card, 'vremade_lucky_mult', 1, card.ability.extra.mult_odds) then
                card.lucky_trigger = true
                ret.mult = card.ability.extra.mult
            end
            if SMODS.pseudorandom_probability(card, 'vremade_lucky_money', 1, card.ability.extra.dollars_odds) then
                card.lucky_trigger = true
                ret.dollars = card.ability.extra.dollars
            end
            -- 'lucky_trigger' is for Lucky Cat. Steamodded cleans this particular variable up for you, but in the general case you should do this:
            --[[
            G.E_MANAGER:add_event(Event {
               func = function()
                   card.lucky_trigger = nil
                   return true
               end
            )
            --]]
            return ret
        end
    end,
}
-- Atlas para Jokers
SMODS.Atlas{
    key = 'Jokers',
    path = 'Jokers.png',
    px = 71,
    py = 95
}

-- Olivia Benedita
  SMODS.Joker{
    key = 'olivia',

    loc_txt = {
        name = 'Olivia Benedita',
        text = {
            'Transforma cartas da {C:attention}Sorte{} em',
            '{C:attention}Cartas de Fã{} quando pontuam',
            'Venda com {C:attention}#1#{} cartas de fã no deck',
            'para criar {C:dark_edition}Olivia Final Boss{}',
            '{C:inactive}(Atualmente: #2#/30)'
        }
    },
    atlas = 'Jokers',
    rarity = 3,
    cost = 6,
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = false,
    perishable_compat = false,
    pos = {x = 0, y = 0},
    config = { extra = { fa_necessarios = 30 } },
    loc_vars = function(self, info_queue, card)
        info_queue[#info_queue + 1] = G.P_CENTERS.m_lucky
        info_queue[#info_queue + 1] = G.P_CENTERS.m_rpgs_carta_fa
        
        local fa_count = 0
        for _, playing_card in ipairs(G.playing_cards or {}) do
            if SMODS.has_enhancement(playing_card, 'm_rpgs_carta_fa') then
                fa_count = fa_count + 1
            end
        end
        
        return { vars = { card.ability.extra.fa_necessarios, fa_count } }
    end,
    calculate = function(self, card, context)
        if context.before and not context.blueprint then
            local lucky_cards = 0
            for _, scored_card in ipairs(context.scoring_hand) do
                if scored_card.ability.effect == 'Lucky Card' then
                    lucky_cards = lucky_cards + 1
                    scored_card:set_ability(G.P_CENTERS.m_rpgs_carta_fa, nil, true)
                    G.E_MANAGER:add_event(Event({
                        func = function()
                            scored_card:juice_up()
                            return true
                        end
                    }))
                end
            end
            if lucky_cards > 0 then
                return {
                    message = 'Virou Fã!',
                    colour = G.C.PURPLE
                }
            end
        end
        
        if context.selling_self and not context.blueprint then
            local fa_count = 0
            for _, playing_card in ipairs(G.playing_cards or {}) do
                if SMODS.has_enhancement(playing_card, 'm_rpgs_carta_fa') then
                    fa_count = fa_count + 1
                end
            end
            
            if fa_count >= card.ability.extra.fa_necessarios then
                if #G.jokers.cards + G.GAME.joker_buffer < G.jokers.config.card_limit then
                    G.GAME.joker_buffer = G.GAME.joker_buffer + 1
                    G.E_MANAGER:add_event(Event({
                        func = function()
                            play_sound('timpani')
                            local new_joker = SMODS.add_card {
                                set = 'Joker',
                                rarity = 'rpgs_cyberolívia',
                                key_append = 'olivia'
                            }
                            G.GAME.joker_buffer = 0
                            
                            card_eval_status_text(new_joker, 'extra', nil, nil, nil, {
                                message = 'CYBER FINAL BOSS!',
                                colour = HEX('8B00FF')
                            })
                            
                            check_for_unlock { type = 'olivia_final' }
                            
                            return true
                        end
                    }))
                end
            end
        end
    end
}
--Raridade
SMODS.Rarity{
    key = 'cyberolívia',
    
    loc_txt = {
        name = 'CyberOlivia',
        text = {
            'CyberOlivia'
        }
    },
    
    -- Cor roxa/cibernética (RGB)
    badge_colour = HEX('8B00FF'),  -- Roxo vibrante
    default_weight = 0,  -- Não aparece em pools normais
    pools = {},  -- Não vai em nenhum pool padrão
    get_weight = function(self)
        return 0  -- Peso 0 = nunca aparece aleatoriamente
    end
}
--Olivia Benedita Final Boss
SMODS.Joker{
    key = 'olivia_final',

    loc_txt = {
        name = 'Olivia Benedita Final Boss',
        text = {
            'Cartas de fã dão {X:mult,C:white}X#1#{} Mult',
            'e tem {C:green}#2# em #3#{} chance de',
            'dar {C:money}$#4#{} ao pontuar'
        }
    },
    atlas = 'Jokers',
    rarity = 'rpgs_cyberolívia',
    cost = 20,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = false,
    perishable_compat = false,
    pos = {x = 1, y = 0},
    config = { extra = { xmult = 3, dollars = 5, dollars_odds = 4 } },
   loc_vars = function(self, info_queue, card)
        info_queue[#info_queue + 1] = G.P_CENTERS.m_rpgs_carta_fa
        return { 
            vars = { 
                card.ability.extra.xmult, 
                G.GAME.probabilities.normal or 1,
                card.ability.extra.dollars_odds,
                card.ability.extra.dollars 
            } 
        }
    end,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play then
            -- Verifica se a carta tem o enhancement Carta Fã
            if SMODS.has_enhancement(context.other_card, 'm_rpgs_carta_fa') then
                -- Aplica X Mult
                local ret = {
                    x_mult = card.ability.extra.xmult,
                    colour = G.C.MULT,
                    card = card
                }
                
                -- Chance de dar dinheiro
                if pseudorandom('olivia_final_money') < G.GAME.probabilities.normal / card.ability.extra.dollars_odds then
                    G.GAME.dollar_buffer = (G.GAME.dollar_buffer or 0) + card.ability.extra.dollars
                    ret.dollars = card.ability.extra.dollars
                    ret.func = function()
                        G.E_MANAGER:add_event(Event({
                            func = function()
                                G.GAME.dollar_buffer = 0
                                return true
                            end
                        }))
                    end
                end
                
                return ret
            end
        end
    end
}
-- Oleg
SMODS.Joker{
    key = 'oleg',

    loc_txt = {
        name = 'Oleg',
        text = {
           "Este round oleg snipará a carta: {C:attention}#2#",
                    "of {V:1}#3#{} e ela vai dar ",
                    "{X:blue,C:white} X#1# {} fichas quando pontuar ",
                    "{s:0.8}A carta snipada muda todo round",
        }
    },
    atlas = 'Jokers',
    rarity = 2,
    cost = 6,
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = false,
    perishable_compat = false,
    pos = {x = 2, y = 0},
    config = { extra = { xchips = 2 } },
    loc_vars = function(self, info_queue, card)
        local idol_card = G.GAME.current_round.idol_card or { rank = 'Ace', suit = 'Spades' }
        return { vars = { card.ability.extra.xchips, localize(idol_card.rank, 'ranks'), localize(idol_card.suit, 'suits_plural'), colours = { G.C.SUITS[idol_card.suit] } } }
    end,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play and
            context.other_card:get_id() == G.GAME.current_round.idol_card.id and
            context.other_card:is_suit(G.GAME.current_round.idol_card.suit) then
            return {
                xchips = card.ability.extra.xchips
            }
        end
    end,
    locked_loc_vars = function(self, info_queue, card)
        return { vars = { number_format(1000000) } }
    end,
    check_for_unlock = function(self, args)                        -- equivalent to `unlock_condition = { type = 'chip_score', chips = 1000000 }`
        return args.type == 'chip_score' and args.chips >= 1000000 -- See note about Talisman on the wiki
    end
}

--- This changes vremade_idol_card every round so every instance of The Idol shares the same card.
--- You could replace this with a context.end_of_round reset instead if you want the variables to be local.
--- See SMODS.current_mod.reset_game_globals at the bottom of this file for when this function is called.
local function reset_vremade_idol_card()
    G.GAME.current_round.idol_card = { rank = 'Ace', suit = 'Spades' }
    local valid_idol_cards = {}
    for _, playing_card in ipairs(G.playing_cards) do
        if not SMODS.has_no_suit(playing_card) and not SMODS.has_no_rank(playing_card) then
            valid_idol_cards[#valid_idol_cards + 1] = playing_card
        end
    end
    local idol_card = pseudorandom_element(valid_idol_cards, 'vremade_idol' .. G.GAME.round_resets.ante)
    if idol_card then
        G.GAME.current_round.idol_card.rank = idol_card.base.value
        G.GAME.current_round.idol_card.suit = idol_card.base.suit
        G.GAME.current_round.idol_card.id = idol_card.base.id
    end
end
-- Bruce
SMODS.Joker{
    key = 'bussy',

    loc_txt = {
        name = 'Bruce',
        text = {
            ''
        }
    },
    atlas = 'Jokers',
    rarity = 3,
    cost = 6,
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = false,
    perishable_compat = false,
    pos = {x = 3, y = 0},
}
-- Kimiko
  SMODS.Joker{
    key = 'kimiko',

    loc_txt = {
        name = 'Kimiko',
        text = {
            ''
        }
    },
    atlas = 'Jokers',
    rarity = 3,
    cost = 6,
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = false,
    perishable_compat = false,
    pos = {x = 4, y = 0},
}
-- Kai
  SMODS.Joker{
    key = 'kai',

    loc_txt = {
        name = 'Kai',
        text = {
            ''
        }
    },
    atlas = 'Jokers',
    rarity = 3,
    cost = 6,
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = false,
    perishable_compat = false,
    pos = {x = 5, y = 0},
}
-- V
  SMODS.Joker{
    key = 'V',

    loc_txt = {
        name = 'V',
        text = {
            ''
        }
    },
    atlas = 'Jokers',
    rarity = 3,
    cost = 6,
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = false,
    perishable_compat = false,
    pos = {x = 6, y = 0},
}
-- Dominique
  SMODS.Joker{
    key = 'Dominique',

    loc_txt = {
        name = 'Dominique',
        text = {
            ''
        }
    },
    atlas = 'Jokers',
    rarity = 3,
    cost = 6,
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = false,
    perishable_compat = false,
    pos = {x = 7, y = 0},
}
-- Nano
    SMODS.Joker{
        key = 'Nano',
    
        loc_txt = {
            name = 'Nano',
            text = {
                ''
            }
        },
        atlas = 'Jokers',
        rarity = 3,
        cost = 6,
        unlocked = true,
        discovered = true,
        blueprint_compat = false,
        eternal_compat = false,
        perishable_compat = false,
        pos = {x = 8, y = 0},
    }



----------------------------------------------
------------MOD CODE END----------------------
    