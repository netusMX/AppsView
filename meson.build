# Project name, programming language and version
project (
    'com.github.netusMX.AppsView',
    'vala', 'c',
    version: '0.0.1'
)

# Translation module
i18n = import ('i18n')
gnome = import('gnome')

prefix = get_option('prefix')
datadir = join_paths(prefix, get_option('datadir'))
libdir = join_paths(prefix, get_option('libdir'))

# Project arguments
add_project_arguments (
    '-DGETTEXT_PACKAGE="@0@"'.format (meson.project_name ()),
    language: 'c'
)

pluginsdir = join_paths(prefix, get_option('libdir'), 'com.github.netusMX.appsView')
add_project_arguments(
    '-DPLUGINSDIR="@0@"'.format(pluginsdir),
    language: 'c'
)

# Listing dependencies
glib_dep = dependency('glib-2.0')
gee_dep = dependency('gee-0.8')
gio_dep = dependency('gio-2.0')
gtk_dep = dependency('gtk+-3.0')
granite_dep = dependency('granite')
gobject_dep = dependency('gobject-2.0')
libsoup_dep = dependency('libsoup-2.4')
appstream_dep = dependency('appstream')
gio_unix_dep = dependency('gio-unix-2.0')
json_glib_dep = dependency('json-glib-1.0')
libgnome_menu_dep = dependency('libgnome-menu-3.0')
webkit2_dep = dependency('webkit2gtk-4.0', version: '>=2.28')
webkit2_web_extension_dep = dependency('webkit2gtk-web-extension-4.0', version: '>=2.28')
libhandy_dep = dependency('libhandy-1', version: '>= 0.83.0')
lightdm_dep = dependency('liblightdm-gobject-1')
posix_dep = meson.get_compiler('vala').find_library('posix')
m_dep = meson.get_compiler('c').find_library('m', required: false)

dependencies = [
    glib_dep,
    gobject_dep,
    gio_dep,
    gio_unix_dep,
    granite_dep,
    gee_dep,
    gtk_dep,
    json_glib_dep,
    libgnome_menu_dep,
    libsoup_dep,
    appstream_dep,
    libhandy_dep,
    webkit2_dep,
    lightdm_dep,
    posix_dep,
    m_dep
]

extension_dependencies = [
    webkit2_web_extension_dep
]

subdir ('src')
subdir ('data')

c_args = [
    '-DGMENU_I_KNOW_THIS_IS_UNSTABLE',
    '-DHANDY_USE_UNSTABLE_API',
]

# Executable
executable (
    meson.project_name (),
    css_gresource,
    sources,
    dependencies: dependencies,
    c_args: c_args,
    install: true
)

subdir ('po')

meson.add_install_script ('meson/post_install.py')
