#if HAS_PLANK
public class AppsView.AppsView : Gtk.Grid, Plank.UnityClient {
#else
public class AppsView.AppsView : Gtk.Grid {
#endif

    public signal void close_indicator ();

    public Backend.AppSystem app_system;
    public Gtk.SearchEntry search_entry;
    public Gtk.Stack stack;
    public AppsViewWindow window;

    private enum Modality {
        NORMAL_VIEW = 0,
        CATEGORY_VIEW = 1,
        SEARCH_VIEW
    }

    public const int DEFAULT_ROWS = 6;

    private unowned Gtk.StyleContext style_context;
    private Gtk.CssProvider? style_provider = null;
    private static Gtk.CssProvider resource_provider;

    private Backend.SynapseSearch synapse;
    private Gdk.Screen screen;
    private Modality modality;
    private Views.Grid grid_view;
    private Views.SearchView search_view;
    private Widgets.BlurBackground backgroundImage;

     static construct {
        resource_provider = new Gtk.CssProvider ();
        resource_provider.load_from_resource ("/com/github/netusMX/appsView/application.css");
    }

    construct {

         string ls_stdout;
         string ls_stderr;
         int ls_status;

        style_context = get_style_context ();
        style_context.add_class ("apps-view-main-window");
        style_context.add_provider (resource_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

        app_system = new Backend.AppSystem ();
        synapse = new Backend.SynapseSearch ();

        screen = get_screen ();

        search_entry = new Gtk.SearchEntry ();
        search_entry.placeholder_text = _("Search");
        search_entry.hexpand = true;
        search_entry.set_alignment (0.5f);
        search_entry.secondary_icon_tooltip_markup = Granite.markup_accel_tooltip (
            {"<Ctrl>BackSpace"}, _("Clear all")
        );
        var search_entry_style_context = search_entry.get_style_context ();
        search_entry_style_context.add_class ("apps-view-search-entry");
        search_entry_style_context.add_provider (resource_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

        var top = new Gtk.Grid ();
        top.add (search_entry);
        top.halign = Gtk.Align.CENTER;
        top.hexpand = true;

        grid_view = new Views.Grid ();
        grid_view.margin_start = 100;
        grid_view.margin_end = 100;
        // category_view = new Widgets.CategoryView (this);

        search_view = new Views.SearchView ();
        stack = new Gtk.Stack () {
            transition_duration = 100,
            transition_type = Gtk.StackTransitionType.CROSSFADE
        };
        stack.add_named (grid_view, "normal");
        // stack.add_named (category_view, "category");
        stack.add_named (search_view, "search");

        var container = new Gtk.Grid ();
        container.row_spacing = 12;
        container.margin_top = 20;
        container.attach (top, 0, 0);
        container.attach (stack, 0, 1);

        // This function must be after creating the page switcher
        grid_view.populate (app_system);

        var event_box = new Gtk.EventBox ();
        event_box.add (container);

        var event_box_style_context = event_box.get_style_context ();
        event_box_style_context.add_class ("apps-view-event-box");
        event_box_style_context.add_provider (resource_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

        var overlay = new Gtk.Overlay();
        var lightdm_user_list = LightDM.UserList.get_instance ();
        var user_name = GLib.Environment.get_user_name();
        if (lightdm_user_list.length > 0) {
            lightdm_user_list.users.foreach ((user) => {
                if (user_name == user.name) {
                    backgroundImage = new Widgets.BlurBackground(user.background);
                }
            });
        } else {
            backgroundImage = new Widgets.BlurBackground(null);
        }

        overlay.add(backgroundImage);
        overlay.add_overlay(event_box);

        // Add the container to the dialog's content area
        this.add (overlay);

        search_view.start_search.connect ((match, target) => {
            search.begin (search_entry.text, match, target);
        });

        focus_in_event.connect (() => {
            search_entry.grab_focus ();
            return Gdk.EVENT_PROPAGATE;
        });

        event_box.key_press_event.connect (on_event_box_key_press);
        search_entry.key_press_event.connect (on_search_view_key_press);

        event_box.key_press_event.connect (on_event_box_key_press);
        search_entry.key_press_event.connect (on_search_view_key_press);

        // Showing a menu reverts the effect of the grab_device function.
        search_entry.search_changed.connect (() => {
            if (modality != Modality.SEARCH_VIEW) {
                set_modality (Modality.SEARCH_VIEW);
            }
            search.begin (search_entry.text);
        });

        search_entry.grab_focus ();
        search_entry.activate.connect (search_entry_activated);

        grid_view.app_launched.connect (() => {
            close_indicator ();
            window.closeApp();
        });

        search_view.app_launched.connect (() => {
            close_indicator ();
            window.closeApp();
        });

        // Auto-update applications grid
        app_system.changed.connect (() => {
            grid_view.populate (app_system);
        });

    }

    public void set_window(AppsViewWindow window) {
        this.window = window;

    }
    private void search_entry_activated () {
        if (modality == Modality.SEARCH_VIEW) {
            search_view.activate_selection ();
        }
    }

    /* These keys do not work if connect_after used; the rest of the key events
     * are dealt with after the default handler in order that CJK input methods
     * work properly */
    public bool on_search_view_key_press (Gdk.EventKey event) {
        var key = Gdk.keyval_name (event.keyval).replace ("KP_", "");

        switch (key) {
            case "Down":
                search_entry.move_focus (Gtk.DirectionType.TAB_FORWARD);
                return Gdk.EVENT_STOP;

            case "Escape":
                if (search_entry.text.length > 0) {
                    search_entry.text = "";
                } else {
                    close_indicator ();
                    window.closeApp();
                }

                return Gdk.EVENT_STOP;
        }

        return Gdk.EVENT_PROPAGATE;
    }

    public bool on_event_box_key_press (Gdk.EventKey event) {
        var key = Gdk.keyval_name (event.keyval).replace ("KP_", "");
        if ((event.state & Gdk.ModifierType.CONTROL_MASK) != 0) {
            return Gdk.EVENT_STOP;
        }

        // Alt accelerators
        if ((event.state & Gdk.ModifierType.MOD1_MASK) != 0) {
            switch (key) {
                case "F4":
                    close_indicator ();
                    return Gdk.EVENT_STOP;

                case "0":
                case "1":
                case "2":
                case "3":
                case "4":
                case "5":
                case "6":
                case "7":
                case "8":
                case "9":
                    if (modality == Modality.NORMAL_VIEW) {
                        int page = int.parse (key);
                        if (page < 0 || page == 9) {
                            grid_view.go_to_last ();
                        } else {
                            grid_view.go_to_number (page);
                        }
                    }

                    // FIXME: Workaround to avoid losing focus completely
                    search_entry.grab_focus ();
                    return Gdk.EVENT_STOP;
            }
        }

        switch (key) {
            case "Down":
            case "Enter": // "KP_Enter"
            case "Home":
            case "KP_Enter":
            case "Left":
            case "Return":
            case "Right":
            case "Tab":
            case "Up":
                return Gdk.EVENT_PROPAGATE;

            case "Page_Up":
                if (modality == Modality.NORMAL_VIEW) {
                    grid_view.go_to_previous ();
                }
                break;

            case "Page_Down":
                if (modality == Modality.NORMAL_VIEW) {
                    grid_view.go_to_next ();
                }
                break;

            case "BackSpace":
                if (!search_entry.has_focus) {
                    search_entry.grab_focus ();
                    search_entry.move_cursor (Gtk.MovementStep.BUFFER_ENDS, 0, false);
                }
                return Gdk.EVENT_PROPAGATE;
            case "End":
                if (modality == Modality.NORMAL_VIEW) {
                    grid_view.go_to_last ();
                }

                return Gdk.EVENT_PROPAGATE;
            default:
                if (!search_entry.has_focus && event.is_modifier != 1) {
                    search_entry.grab_focus ();
                    search_entry.move_cursor (Gtk.MovementStep.BUFFER_ENDS, 0, false);
                    search_entry.key_press_event (event);
                }
                return Gdk.EVENT_PROPAGATE;

        }

        return Gdk.EVENT_STOP;
    }

    public void show_slingshot () {
        search_entry.text = "";

    /* TODO
        set_focus (null);
    */

        search_entry.grab_focus ();
        // This is needed in order to not animate if the previous view was the search view.
        // view_selector_revealer.transition_type = Gtk.RevealerTransitionType.NONE;
        stack.transition_type = Gtk.StackTransitionType.NONE;
        set_modality (Modality.NORMAL_VIEW);
        // view_selector_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_RIGHT;
        stack.transition_type = Gtk.StackTransitionType.CROSSFADE;
    }

    private void set_modality (Modality new_modality) {
        modality = new_modality;

        switch (modality) {
            case Modality.NORMAL_VIEW:
                stack.set_visible_child_name ("normal");
                search_entry.grab_focus ();
                break;

            case Modality.SEARCH_VIEW:
                stack.set_visible_child_name ("search");
                break;

        }
    }

    private async void search (string text, Synapse.SearchMatch? search_match = null,
        Synapse.Match? target = null) {

        var stripped = text.strip ();

        if (stripped == "") {
            // this code was making problems when selecting the currently searched text
            // and immediately replacing it. In that case two async searches would be
            // started and both requested switching from and to search view, which would
            // result in a Gtk error and the first letter of the new search not being
            // picked up. If we add an idle and recheck that the entry is indeed still
            // empty before switching, this problem is gone.
            Idle.add (() => {
                if (search_entry.text.strip () == "")
                    set_modality (Modality.NORMAL_VIEW);
                return false;
            });
            return;
        }

        if (modality != Modality.SEARCH_VIEW)
            set_modality (Modality.SEARCH_VIEW);

        Gee.List<Synapse.Match> matches;

        if (search_match != null) {
            search_match.search_source = target;
            matches = yield synapse.search (text, search_match);
        } else {
            matches = yield synapse.search (text);
        }

        Idle.add (() => {
            search_view.set_results (matches, text);
            return false;
        });
    }
}
