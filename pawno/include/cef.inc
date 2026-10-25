#if !defined CEFSAMP_INC_
#define CEFSAMP_INC_
enum CEF_ValueType { CEF_STRING, CEF_INTEGER, CEF_FLOAT }
#define CEFSTR(%0) CEF_STRING, %0
#define CEFINT(%0) CEF_INTEGER, %0
#define CEFFLOAT(%0) CEF_FLOAT, %0
native cef_create_browser(player_id, browser_id, const url[], bool:hidden, bool:focused);
native cef_destroy_browser(player_id, browser_id);
native cef_on_player_connect(player_id, const ip[]);
native cef_on_player_disconnect(player_id);
native cef_emit_event(player_id, const event[], {CEF_ValueType, Float, _}:...);
native cef_subscribe(const event[], const callback[]);
native cef_hide_browser(player_id, browser_id, bool:hide);
native cef_player_has_plugin(player_id);
native cef_focus_browser(player_id, browser_id, bool:focused);
native cef_load_url(player_id, browser_id, const url[]);
forward OnCefInitialize(player_id, success);
forward OnCefBrowserCreated(player_id, browser_id, status_code);
#endif
