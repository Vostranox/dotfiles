static int topbar = 0;
static int fuzzy  = 1;

static const char *fonts[] = {
	"JetBrainsMono Nerd Font:size=8"
};

static const char *prompt = NULL;

static const char *colors[SchemeLast][2] = {
	[SchemeNorm] = { "#c8c8d5", "#181818" },
	[SchemeSel]  = { "#95a99f", "#181818" },
	[SchemeOut]  = { "#000000", "#96a6c8" },
};

static unsigned int lines = 0;

static const char worddelimiters[] = " ";
