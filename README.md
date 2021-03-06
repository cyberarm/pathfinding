# Pathfinding

## Usage
`ruby pathfinding.rb [options]`

At startup a random starting and targeting position are choosen

Options:
* `--fullscreen`, `-f`  - Make with fullscreen
* `--threaded`, `-t`    - Enables using a thread to finish search as fast as possible, instead of animating it.
* `--nodiagonal`, `-nd` - Disable diagonal paths
* `--floodfill`, `-w`   - Use flood fill by default

Input:
* F5           - Find path
* `            - Toggle between pathfinding algorithms
* Left Mouse   - Set starting position, if over a tile
* Middle Mouse - Place tile, if no tile already there
* Right Mouse  - Set target position, if over a tile
* Scroll Wheel - Zoom in at out
* Arrow Keys   - Move map about
* R            - Delete tile under mouse
* Tab          - Toggle visualization of pending and visited nodes
* -/=          - Change steps per frame for pathfinder, defaults to 1