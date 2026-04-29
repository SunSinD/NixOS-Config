#!/usr/bin/env python3
"""Pin a screenshot to the screen as a floating, draggable window."""
import gi
gi.require_version("Gtk", "3.0")
from gi.repository import Gtk, Gdk, GdkPixbuf
import sys

class PinWindow(Gtk.Window):
    def __init__(self, path):
        super().__init__(type=Gtk.WindowType.TOPLEVEL)
        self.set_decorated(False)
        self.set_resizable(False)
        self.set_keep_above(True)
        self.set_skip_taskbar_hint(True)
        self.set_skip_pager_hint(True)
        self.set_app_paintable(True)

        pixbuf = GdkPixbuf.Pixbuf.new_from_file(path)
        image = Gtk.Image.new_from_pixbuf(pixbuf)

        frame = Gtk.Frame()
        frame.set_shadow_type(Gtk.ShadowType.NONE)
        frame.add(image)

        event_box = Gtk.EventBox()
        event_box.add(frame)
        event_box.connect("button-press-event", self.on_press)
        self.add(event_box)

        self.connect("key-press-event", self.on_key)

        css = Gtk.CssProvider()
        css.load_from_data(b"window { border: 1px solid rgba(180,180,180,0.5); background: transparent; }")
        Gtk.StyleContext.add_provider_for_screen(
            Gdk.Screen.get_default(), css,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION,
        )
        self.show_all()

    def on_press(self, widget, event):
        if event.button == 1:
            self.begin_move_drag(int(event.button), int(event.x_root), int(event.y_root), event.time)
        elif event.button == 3:
            Gtk.main_quit()

    def on_key(self, widget, event):
        if event.keyval in (Gdk.KEY_Escape, Gdk.KEY_q):
            Gtk.main_quit()

if __name__ == "__main__":
    if len(sys.argv) < 2:
        sys.exit(1)
    PinWindow(sys.argv[1])
    Gtk.main()
