const theme_pref_mq = window.matchMedia && window.matchMedia("(prefers-color-scheme: dark)");

const ls_key = "theme";
const ls_dark_val = "dark";
const ls_light_val = "light";

const css_id_base = "css-theme-pref-";
const button_id_base = "button-switch-";

const css_light = document.getElementById(css_id_base + ls_light_val);
const css_dark = document.getElementById(css_id_base + ls_dark_val);
const button_light = document.getElementById(button_id_base + ls_light_val);
const button_dark = document.getElementById(button_id_base + ls_dark_val);

const change_theme = (to_dark) => {
  if (to_dark) {
    css_light.disabled = true;
    css_dark.disabled = false;
    localStorage.setItem(ls_key, ls_dark_val);
  } else {
    css_dark.disabled = true;
    css_light.disabled = false;
    localStorage.setItem(ls_key, ls_light_val);
  }
};
const change_button = (to_dark) => {
  if (to_dark) {
    button_light.parentElement.style.display = "inline-block";
    button_dark.parentElement.style.display = "none";
  } else {
    button_dark.parentElement.style.display = "inline-block";
    button_light.parentElement.style.display = "none";
  }
};

{
  const to_dark = localStorage.getItem(ls_key);
  if (to_dark) {
    const chk = to_dark === ls_dark_val;
    change_button(chk);
    change_theme(chk);
  } else {
    change_button(theme_pref_mq && theme_pref_mq.matches);
  }
}

[[button_light, false], [button_dark, true]].forEach(([n, v]) => {
  n.addEventListener("click", function() { change_button(v); change_theme(v); });
});

theme_pref_mq.addEventListener("change", (e) => {
  change_button(e.matches);
  css_dark.disabled = css_light.disabled = true;
  localStorage.removeItem(ls_key);
});
