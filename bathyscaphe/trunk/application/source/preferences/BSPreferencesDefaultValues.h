//
// BathyScaphe
// Preference Default Values List
// For Baby Universe Day
//

// AppDefaults
#define kPreferencesDefault_OnlineMode		YES
#define DEFAULT_IS_BROWSER_VERTICAL			NO
#define DEFAULT_CONTENTS_SEARCH_OPTION		CMRSearchOptionCaseInsensitive
#define DEFAULT_SEARCH_PANEL_EXPANDED		YES
//#define DEFAULT_BROWSER_SORT_ASCENDING		YES
//#define DEFAULT_BROWSER_STATUS_FILTERINGMAS	0
#define DEFAULT_MAX_FOR_THREADS_HISTORY		20
#define DEFAULT_MAX_FOR_BOARDS_HISTORY		10
#define DEFAULT_MAX_FOR_SEARCH_HISTORY		10
#define DEFAULT_INFORM_WHEN_DAT_OCHI		YES
#define DEFAULT_OLD_SCROLLING				NO
#define DEFAULT_USE_BINARY_FORMAT			NO
#define DEFAULT_TGREP_SEARCH_OPTION         BSTGrepSearchByNew
#define DEFAULT_NINJA_AUTO_RETRY            YES
#define DEFAULT_INFO_SERVER_DATA_REMOVED    NO
#define DEFAULT_APP_RESET_TARGET_MASK       BSAppResetAll
#define DEFAULT_NONAME_ENTITYREF_CONVERTED  NO

// FontsAndColor
#define DEFAULT_MESSAGE_ANCHOR_HAS_UNDERLINE	YES
#define DEFAULT_PARAGRAPH_INDENT				40.0f
#define DEFAULT_REPLY_FONTSIZE					12.0f
#define DEFAULT_IS_RESPOPUP_TEXT_COLOR			NO
#define DEFAULT_POPUP_SCROLLER_SMALL			YES
#define DEFAULT_TV_IDX_SPACING_BEFORE			15.0f
#define DEFAULT_TV_IDX_SPACING_AFTER			10.0f
#define DEFAULT_THREAD_LIST_ROW_HEIGHT			17.0f
#define DEFAULT_THREAD_LIST_DRAWSGRID			NO
#define DEFAULT_THREADS_LIST_FONTSIZE			12.0f
#define DEFAULT_BOARD_LIST_ROWSIZESTYLE         2
#define DEFAULT_BOARD_LIST_SHOWS_ICON           YES
#define DEFAULT_SHOULD_THREAD_ANTIALIAS			YES
#define DEFAULT_THREADS_VIEW_FONTSIZE			12.0f
#define DEFAULT_HOST_FONTSIZE					10.0f
#define DEFAULT_BEPROFILELINK_FONTSIZE			10.0f
#define OLD_DEFAULT_MESSAGE_NAME_COLOR			[NSColor colorWithCalibratedRed:0.0f green:0.56f blue:0.0f alpha:1.0f]
#define OLD_DEFAULT_MESSAGE_TITLE_COLOR			[NSColor colorWithCalibratedRed:0.56f green:0.0f blue:0.0f alpha:1.0f]

// ThreadViewer
#define kPreferencesDefault_MailAttachmentShown	YES
#define kPreferencesDefault_MailAddressShown	YES
#define DEFAULT_THREAD_VIEWER_LINK_TYPE			ThreadViewerResPopUpLinkType
#define DEFAULT_TV_MAILTO_LINK_TYPE				ThreadViewerResPopUpLinkType
#define DEFAULT_SHOWS_POOF_ON_ABONE				YES
//#define DEFAULT_TV_FIRST_VISIBLE				1
//#define DEFAULT_TV_LAST_VISIBLE					50
#define DEFAULT_TV_PREVIEW_WITH_NO_MODIFIER		YES
#define DEFAULT_TV_MOUSEDOWN_TIME				0.5
#define DEFAULT_TV_SCROLL_TO_NEW				NO
#define DEFAULT_OPEN_IN_BROWSER_TYPE			0
//#define DEFAULT_TV_SHOWS_ALL_WHEN_DOWNLOADED	NO
//#define DEFAULT_LINK_DOWNLOADER_ATTACH_COMMENT	NO
#define DEFAULT_TV_AUTORELOAD_WHEN_WAKE			NO
#define DEFAULT_TV_SAAP_ICON_SHOWN				YES
#define DEFAULT_TV_CONVERTS_ITMS                YES
#define DEFAULT_TV_GESTURE_ENABLED              YES
//#define DEFAULT_TV_FORCE_LAYOUT                 YES
#define DEFAULT_TV_COLOR_ID                     YES
#define DEFAULT_TV_SHOWS_REF_MARKER             NO

// Accounts
#define DEFAULT_LOGIN_MARU_IF_NEEDED	NO
#define DEFAULT_LOGIN_BE_ANY_TIME		NO
#define DEFAULT_USE_KEYCHAIN			NO

// Bundle
#define DEFAULT_BW_BBSMENU_URL		@"http://azlucky.s25.xrea.com/2chboard/bbsmenu2.html"
#define DEFAULT_BW_AUTOSYNC			YES
#define DEFAULT_BW_SYNC_INTERVAL	BSAutoSyncBy2weeks

// Filter
#define DEFAULT_SPAMFILTER_ENABLED			YES
#define DEFAULT_SPAMFILTER_BEHAVIOR			kSpamFilterLocalAbonedBehavior
#define DEFAULT_AAD_ENABLED					YES
#define DEFAULT_AAD_TRAET_AA_AS_SPAM		NO
#define DEFAULT_TREAT_NO_SAGE_AS_SPAM       NO
#define DEFAULT_SCOPE_FOR_ADDING            BSAddNGExBoardScopeType
#define DEFAULT_RUN_AFTER_ADDING            YES
#define DEFAULT_REGISTRANT_CONSIDER_NAME    YES

// ThreadsList
#define DEFAULT_TLSEL_HOLDING_MASK			CMRAutoscrollStandard
#define DEFAULT_TL_INCREMENTAL_SEARCH		YES
#define DEFAULT_TL_AUTORELOAD_WHEN_WAKE		NO
#define DEFAULT_HEADCHECK_INTERVAL			300.0
#define DEFAULT_TL_VIEW_MODE				BSThreadsListShowsLiveThreads
#define DEFAULT_TL_INVALID_DESC_FIXED		NO
#define DEFAULT_TL_SORT_IMMEDIATELY         YES
#define DEFAULT_TL_DRAWS_LABELCOLOR         YES
#define DEFAULT_TL_NEXT_UPDATED_CONTAINS_NEW    NO
//#define DEFAULT_TL_SPLITVIEW_USES_THIN_DIVIDER  NO

// Background
#define DEFAULT_STABLE_DRAWS_STRIPED	YES
//#define DEFAULT_BOARD_LIST_BG_COLOR		[NSColor colorWithCalibratedRed:0.831 green:0.867 blue:0.902 alpha:1.0]
//#define DEFAULT_BOARD_LIST_NONACTIVE_BG_COLOR	[NSColor colorWithCalibratedRed:0.91 green:0.91 blue:0.91 alpha:1.0]
#define DEFAULT_POPUP_BG_COLOR			[NSColor colorWithCalibratedHue:0.14f saturation:0.2f brightness:1.0f alpha:1.0f]
#define DEFAULT_POPUP_BG_ALPHA			0.85
#define DEFAULT_REPLY_BG_ALPHA			1.0

// Sounds
#define DEFAULT_SOUND_HEADCHECK_NEW		@"Ping"
#define DEFAULT_SOUND_HEADCHECK_NONE	@"Basso"
#define DEFAULT_SOUND_HEADCHECK_REPLY	@""

// PP
#define DEFAULT_PANE_ID_BOARD_INFO_INSPECTOR    @"general"