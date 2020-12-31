# SystemY
A keyboard, display and cassette interface for the Yarrb2 board.

When I designed the Yarrb2 board I kept in mind that it should be possible to use the board as a stand-alone system. Back then I already set my mind on making it some kind of System 1 clone. I explicitly say that this is a System1 clone and not a replica because the hardware doesn't look anything like an original System 1. Besides the original options like 1152 bytes RAM, 512 bytes ROM, 300 baud cassette, eight character display and 25 keys this version has the following additional options:

* The memory can be expanded to (almost) 60KB RAM and 4KB ROM (in the current CPLD version, you can of course expand it to 128K + 128K but that seems a bit overdone to me)
* RAM between #8000 - #EFFF can be write protected
* The reset button can be configured to generate an NMI or IRQ
* You have access to eight useless LEDs (because they are on the back side of the system)
* With a suitable CPU this system can run at 1, 2 of 4MHz
* The cassette output can be programmed to act like the Atom 1-bit audio

The cassette in-out is the most difficult part of the project and this is not working yet. I can output a 1200Hz and 2400Hz tone by clearing or setting bit 6 of port A (#E20) and when I save a block of data it sounds like there is a data stream. However, a connected Atom cannot load the data. Also writing to tape and reading back does not work. The CPLD will reset bit 7 of #E20 to 0 when there is a 1200Hz tone at the cassette input and set that bit to 1 if there is a 2400Hz tone. But reading data from an Atom, recorded tape or WAV file does not work although the signal looks nice on my oscilloscope.

And of course I had a lot of design mistakes on this board :shock: I forgot a series resistor for each digit, swapped inputs of the LM358 and I swapped the in and out of the cassette connector. Since I don't expect that somebody wants such a board I didn't mention it, but I record it here just to not forget these issues....

The KiCad files contain the diagram (also in PDF) and the gerber files.

## Copyright and disclosure

You are free to copy and use these files as you want to. However, I don't guarantee any support for your own projects.

The hardware and software in this project are as-is. No warranties, use at your own risk and do not use these in medical or life-supporting devices. Please don't blame me if something goes wrong.
