local utils = require"src/util"
local p8scii_col = utils.p8scii_col

theme = {
	color = {
		selected = 10,
		active = 25,
		highlight = 22,
		secondary_highlight = 47,
		primary = 5,
		secondary = 9,
		scroll_background = 57,
		background = 21,
		border = 38,
		text = 7,
		sfx_grid = {
			selector_color = 47,
			highlight_text_even = 9,
			highlight_text_odd = 25,
			text_even = 7,
			text_odd = 6,
			text_active = 10
		},
		sfx_rows = {
			pitch = 7,
			instrument = 25,
			volume = 9,
			effect_kind = 22,
			effect_value = 22,
			selection = 15,
			background = 0,
			beat_highlight = 37,
			strong_beat_highlight = 40
		}
	},
	metrics = {
		font_height = 7,
		scrollbar_width = 8,
		margin = 2,
		padding = 2,
		sfx_rows = {}
	}
}

local sfx_rows_theme = theme.color.sfx_rows
theme.metrics.sfx_rows = {
	pitch_col = fmt("\f%s", p8scii_col(sfx_rows_theme.pitch)),
	inst_col = fmt("\f%s", p8scii_col(sfx_rows_theme.instrument)),
	vol_col = fmt("\f%s", p8scii_col(sfx_rows_theme.volume)),
	effect_kind_col = fmt("\f%s", p8scii_col(sfx_rows_theme.effect_kind)),
	effect_value_col = fmt("\f%s", p8scii_col(sfx_rows_theme.effect_value)),
}

local sfx_rows_metrics = theme.metrics.sfx_rows
sfx_rows_metrics.formattable_row = fmt(
	"%s%%s\-h%s%%s\-h%s%%s\-h%s%%s%%s",
	sfx_rows_metrics.pitch_col,
	sfx_rows_metrics.inst_col,
	sfx_rows_metrics.vol_col,
	sfx_rows_metrics.effect_kind_col,
	sfx_rows_metrics.effect_value_col
)
