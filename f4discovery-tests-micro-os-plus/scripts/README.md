# Helper scripts

## Prerequisites

These scripts were created on macOS, and the ones suffixed with `.command` are specific to macOS; the `.sh` scripts should also be fine on GNU/Linux, Windows MSYS2, and on the new [Windows Subsystem for Linux](https://msdn.microsoft.com/commandline/wsl/about).

For those who insist on native Windows, separate PowerShell scripts would be required, but considering Microsoft's move towards Linux, this would probably not be worth the effort. Anyway, if you manage to create them, please consider improving your karma and contribute them back to the community.

## generate.sh

Recreate the content of the `generated` folder.

Note: be sure Eclipse is closed while running this script.


```
$ bash scripts/generate.sh
```

The resulting folder is marked as read/only.

To generate a read/write foldder, use `--read-write`

```
$ bash scripts/generate.sh --read-write
```

## generate.mac.command

Wrapper for macOS; execute it by double clicking in Finder.

For selected users, the script uses the development tree as source.
