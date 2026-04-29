# Isotope OS

Isotope is a simple operating system designed to run directly from a floppy
disk on an i486. The goal isn't to create a new modern experience, but learn
about old hardware and try to make it a little usable and fun to use again.

## Building

To build Isotope, simply run the following command:

```bash
make
```

This will output the final floppy image to `build/floppy.img`

## Running

To run Isotope, run the following command:

```bash
make run
```

If you made changes to the source you can also build and run at the same time:

```bash
make all run
```

## License

Isotope OS is licensed under the GNU GPL v3.0 License. See [COPYING] for more details.

Copyright © 2026 Viktor Popp

[COPYING]: COPYING
