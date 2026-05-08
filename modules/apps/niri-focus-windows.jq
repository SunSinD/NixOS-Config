def appid: (.app_id // .appId // .["app-id"] // "");
def title: (.title // .name // "");

[
  (
    (.Ok.Windows // .windows // .Windows // [])[]?
    | select(((appid | tostring) + " " + (title | tostring)) | test($p))
  )
]
| sort_by(.id)
| .[-1].id
// empty
