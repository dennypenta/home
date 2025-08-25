local Colors = require("config.colors")

local function oklch_to_hex(l, c, h)
  local rad = math.rad(h)
  local a = math.cos(rad) * c
  local b = math.sin(rad) * c

  -- OKLab to LMS
  local l_ = l + 0.3963377774 * a + 0.2158037573 * b
  local m_ = l - 0.1055613458 * a - 0.0638541728 * b
  local s_ = l - 0.0894841775 * a - 1.2914855480 * b

  l_ = l_ * l_ * l_
  m_ = m_ * m_ * m_
  s_ = s_ * s_ * s_

  -- LMS to linear sRGB
  local r = 4.0767416621 * l_ - 3.3077115913 * m_ + 0.2309699292 * s_
  local g = -1.2684380046 * l_ + 2.6097574011 * m_ - 0.3413193965 * s_
  local b = -0.0041960863 * l_ - 0.7034186147 * m_ + 1.7076147010 * s_

  -- Clamp and gamma encode
  local function clamp(x)
    return math.min(math.max(x, 0), 1)
  end

  local function encode(x)
    return string.format("%02x", math.floor(clamp(x) ^ (1 / 2.2) * 255 + 0.5))
  end

  return "#" .. encode(r) .. encode(g) .. encode(b)
end

local oklch_pattern = 'oklch%(%s*[%d%.]+%s+[%d%.]+%s+[%d%.]+%s*/?%s*[%d%.]*%)'
local oklch_content = "oklch%(%s*([%d%.]+)%s+([%d%.]+)%s+([%d%.]+)"
-- TODO: just use eero-lehtinen/oklch-color-picker.nvim

return {
  'echasnovski/mini.hipatterns',
  pin = true,
  config = function()
    local hipatterns = require('mini.hipatterns')
    local opts = {
      highlighters = {
        -- Highlight standalone 'FIXME', 'HACK', 'TODO', 'NOTE'
        fixme     = { pattern = '%f[%w]()FIXME()%f[%W]', group = 'MiniHipatternsFixme' },
        hack      = { pattern = '%f[%w]()HACK()%f[%W]', group = 'MiniHipatternsHack' },
        todo      = { pattern = '%f[%w]()TODO()%f[%W]', group = 'MiniHipatternsTodo' },
        note      = { pattern = '%f[%w]()NOTE()%f[%W]', group = 'MiniHipatternsNote' },
        -- Highlight hex color strings (`#rrggbb`) using that color
        hex_color = hipatterns.gen_highlighter.hex_color(),
        oklch     = {
          pattern = oklch_pattern,
          group = function(_, match)
            local l, c, h = match:match(oklch_content)
            if not l or not c or not h then return nil end
            local hex = oklch_to_hex(tonumber(l), tonumber(c), tonumber(h))
            return hipatterns.compute_hex_color_group(hex, 'bg')
          end,
        },
      },
    }

    vim.api.nvim_set_hl(0, 'MiniHipatternsTodo', { fg = Colors.todo, bg = 'none', bold = true })
    vim.api.nvim_set_hl(0, 'MiniHipatternsFixme', { fg = Colors.fixme, bg = 'none', bold = true })
    vim.api.nvim_set_hl(0, 'MiniHipatternsHack', { fg = Colors.hack, bg = 'none', bold = true })
    vim.api.nvim_set_hl(0, 'MiniHipatternsNote', { fg = Colors.note, bg = 'none', bold = true })

    hipatterns.setup(opts)
  end
}
