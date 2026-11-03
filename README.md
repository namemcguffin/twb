# `twb`: typst website builder

provides a package to build typst-based websites

## installation

this package can be installed as follows:

```bash
git clone 'https://github.com/namemcguffin/twb.git' ~/'.local/share/typst/packages/local/twb/0.1.0'
```

## usage

this package provides a single entrypoint function: `build-site`.
it can be used as follows:

```typst
#import "@local/twb:0.1.0": build-site

#build-site(
  [SITE TITLE],
  path("PATH TO BUNDLE SOURCE"),
  (
    // entries should be of form - PATH_OF_OUTPUT: ( path(PATH_TO_SOURCE), [TITLE OF PAGE] )
    "index.html": (path("PATH TO PAGE SOURCE FILE"), [home]),
    "something.html": (path("PATH TO PAGE SOURCE FILE"), [something else]),
    "document.pdf": (path("PATH TO PAGE SOURCE FILE"), [a PDF file]),
  ),
)
```

a build of the resulting website can then be built by just using `typst c --format=bundle`.

### styling

this package bundles a (basic) default set of CSS files.
you can override these defaults via the following (optional) arguments to `build-site`:
- `light_css` (CSS file loaded w/ light mode preference)
- `dark_css` (CSS file loaded w/ dark mode preference)
- `extra_css` (a dictionary mapping output location to source file path)

## license notice

code in this repo is licensed under the [EUPL-1.2](https://interoperable-europe.ec.europa.eu/collection/eupl/eupl-text-eupl-12) license.

as such, to comply with license terms, a copy of source code for this package is added into the output directory.
moreover, copies of source code for all website-relevant files are also added into the output directory.
all of these copies are also linked as `<a hidden>` entries in the `<footer>` section of each output page.
