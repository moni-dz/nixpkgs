{ lib, fetchFromGitHub, python3Packages, glib, cairo, pango, pkg-config, libnotify, libxcb, xcbutilcursor }:

let cairocffi-xcffib = python3Packages.cairocffi.override {
  withXcffib = true;
};
in

python3Packages.buildPythonApplication rec {
  name = "qtile-${version}";
  version = "0.17.0";

  src = fetchFromGitHub {
    owner = "qtile";
    repo = "qtile";
    rev = "v${version}";
    sha256 = "sha256-HHS9/zpzJq9oA610/WA6U2vsRX/obn13lJLfNLNkOlg=";
  };

  patches = [
    ./0001-Substitution-vars-for-absolute-paths.patch
    ./0002-Restore-PATH-and-PYTHONPATH.patch
  ];

  postPatch = ''
    substituteInPlace libqtile/core/manager.py --subst-var-by out $out
    substituteInPlace libqtile/pangocffi.py --subst-var-by glib ${glib.out}
    substituteInPlace libqtile/pangocffi.py --subst-var-by pango ${pango.out}
    substituteInPlace libqtile/backend/x11/xcursors.py --subst-var-by xcb-cursor ${xcbutilcursor.out}
  '';

  SETUPTOOLS_SCM_PRETEND_VERSION = version;

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ glib libnotify libxcb cairo pango python3Packages.xcffib ];

  pythonPath = with python3Packages; [
    xcffib
    cairocffi-xcffib
    setuptools
    setuptools_scm
    dateutil
    dbus-python
    libnotify
    mpd2
    psutil
    pyxdg
    pygobject3
  ];

  postInstall = ''
    wrapProgram $out/bin/qtile \
      --run 'export QTILE_WRAPPER=$0' \
      --run 'export QTILE_SAVED_PYTHONPATH=$PYTHONPATH' \
      --run 'export QTILE_SAVED_PATH=$PATH'
  '';

  doCheck = false; # Requires X server #TODO this can be worked out with the existing NixOS testing infrastructure.

  meta = with lib; {
    homepage = "http://www.qtile.org/";
    license = licenses.mit;
    description = "A small, flexible, scriptable tiling window manager written in Python";
    platforms = platforms.linux;
    maintainers = with maintainers; [ kamilchm ];
  };
}
