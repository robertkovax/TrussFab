# The Frontend

Sketup has an API for the [UI](http://ruby.sketchup.com/UI.html). It allows to create new browser windows within Sketchup. TrussFab's UI is based on those browser windows.

## Folder Structure

In [dialogs](./dialogs) are the ruby files that invoke new browser windows. In [trussfab-global](./trussfab-globals) are files (e.g. styles) that are used in multipled windows. All other folders should represent one window (a _sub-project_) or a concept of windows (e.g. [context-menus](./context-menus)).

## Development

Each sub-project that requires building files ( or _compiling_), should have the option to watch the files for changes an automatically build it. For instace in [animation pane](./animation-pane), you just need to run `yarn start` to watch the files. On every change, yarn builds the new files automatically. In Sketchup, you still need to reun `TrussFab.reload` though.
