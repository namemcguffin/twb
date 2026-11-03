#let build-site = {
  let src_prefix = ".source/"

  // hack way to turn a path to a string using repr
  let path-to-str = {
    let pat = regex("path\(\"/(.+)\"\)")
    e => repr(e).match(pat).captures.at(0)
  }

  let wrap_cache_bust = {
    // hash function adapted from 32-bit FNV-1a
    // (typst only has a 64-bit _signed_ integer type and integer multiplication _panics_ on overflow)
    let (fnv_prime, fnv_offset) = (16777619, 2166136261)
    let wrap_val = calc.div-euclid(int.max, fnv_prime)
    let hash = b => array(b).fold(fnv_offset, (a, c) => calc.rem(a.bit-xor(c), wrap_val) * fnv_prime)

    (pth, src) => (
      pth
        + "?cache_bust="
        + str(hash(array(read(src, encoding: none))))
        + sys.inputs.at("twb.cache_bust_suffix", default: "")
    )
  }

  let mk_html = (e, page_title, hdr, ftr, light_css, dark_css, extra_css) => html.html(lang: "en", {
    html.head({
      html.title[eafana.net #sym.bar.v #page_title]

      html.meta(charset: "utf-8")
      html.meta(name: "viewport", content: "width=device-width, initial-scale=1")

      html.style(
        (
          "@import url(\"",
          wrap_cache_bust("/css/light.css", light_css),
          "\"); @import url(\"",
          wrap_cache_bust("/css/dark.css", dark_css),
          "\") (prefers-color-scheme: dark);",
        ).join(),
      )

      (
        "light": light_css,
        "dark": dark_css,
      )
        .pairs()
        .map(((sheet, src)) => html.link(
          rel: "stylesheet",
          href: wrap_cache_bust("/css/" + sheet + ".css", src),
          disabled: true,
          id: "css-theme-pref-" + sheet,
        ))
        .join()

      extra_css.pairs().map(((k, v)) => html.link(rel: "stylesheet", href: wrap_cache_bust("/" + k, v))).join()

      html.script(defer: true, src: wrap_cache_bust("/js/theme.js", "/static/js/theme.js"))
    })

    html.body({
      html.header(hdr)

      html.hr()

      html.main({
        // workaround for:
        // - https://github.com/typst/typst/issues/7912
        // - https://github.com/typst/typst/issues/8308
        show list: ul => html.ul(ul.children.map(li => html.li(li.body)).join())

        e
      })

      html.footer(ftr)
    })
  })

  let mk_header = (cur, h1, pages, unlisted_pages) => {
    let nle = (lnk, e, is_cur) => html.li(if is_cur { e } else { link(lnk, e) })

    {
      nle("/", title(h1), cur == pages.at("index.html").at(1))

      html.nav(
        html.ul({
          pages
            .pairs()
            .filter(((k, _)) => k not in ("index.html", ..unlisted_pages))
            .map(((k, v)) => {
              nle("/" + k.trim("/index.html", at: alignment.end), v.at(1), cur == v.at(1))
            })
            .join()

          (
            ("button-switch-light", emoji.brightness.high),
            ("button-switch-dark", emoji.brightness.low),
          )
            .map(((id, emj)) => html.li(style: "display: none;", html.elem("button", attrs: ("id": id), emj)))
            .join()
        }),
      )
    }
  }

  let mk_footer = (bundle_path, src, deps) => {
    html.a(href: "/" + src_prefix + path-to-str(src), type: "text/vnd.typst", hidden: true)[source page file]
    deps.map(((path: p, body: b, ..v)) => html.a(href: "/" + src_prefix + path-to-str(p), hidden: true, ..v, b)).join()
    html.a(href: "/" + src_prefix + path-to-str(bundle_path), type: "text/vnd.typst", hidden: true)[source bundle file]

    html.a(href: "/" + src_prefix + "twb/lib.typ", type: "text/vnd.typst", hidden: true)[`twb` source file]
    html.a(
      href: "/" + src_prefix + "twb/LICENSE",
      type: "text/plain;charset=utf-8",
      hidden: true,
      rel: "license",
    )[`twb` license (EUPL-1.2)]
  }

  (h1, bundle_path, pages, unlisted_pages: ("404.html",), light_css: none, dark_css: none, extra_css: none) => {
    asset(src_prefix + "twb/LICENSE", read("/LICENSE"))
    asset(src_prefix + path-to-str(bundle_path), read(bundle_path))
    asset(src_prefix + "twb/lib.typ", read("/lib.typ"))
    asset("js/theme.js", read("/static/js/theme.js"))

    if light_css == none {
      light_css = "/static/css/light.css"
    }
    if dark_css == none {
      dark_css = "/static/css/dark.css"
    }
    if extra_css == none {
      extra_css = ("css/main.css": "/static/css/main.css")
    }

    ("css/light.css": light_css, "css/dark.css": dark_css, ..extra_css)
      .pairs()
      .map(((k, v)) => asset(k, read(v)))
      .join()

    asset(
      "sitemap.xml",
      (
        "<?xml version='1.0' encoding='UTF-8'?>",
        "<urlset ",
        "  xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance'",
        "  xsi:schemaLocation='http://www.sitemaps.org/schemas/sitemap/0.9 http://www.sitemaps.org/schemas/sitemap/0.9/sitemap.xsd'",
        "  xmlns='http://www.sitemaps.org/schemas/sitemap/0.9'>",
        ..(pages.keys().map(e => "<url><loc>/" + e + "</loc></url>")),
        "</urlset>",
      ).join("\n"),
    )

    pages
      .pairs()
      .map(((trg, (src, page_title, ..deps))) => {
        let e = include src
        if trg.ends-with(".html") {
          e = mk_html(
            e,
            page_title,
            mk_header(page_title, h1, pages, unlisted_pages),
            mk_footer(bundle_path, src, deps),
            light_css,
            dark_css,
            extra_css,
          )
        }

        asset(src_prefix + path-to-str(src), read(src))
        deps.map(((path: p, ..args)) => asset(src_prefix + path-to-str(p), read(p))).join()

        document(trg, e, title: page_title)
      })
      .join()
  }
}
