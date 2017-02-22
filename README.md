# verilog-support.vim 

This is a vim plugin that is heavily based on [perl-support](https://github.com/WolfgangMehner/perl-support) by Fritz and
Wolfgang Mehner. I've followed their architecture and a lot of his code structure
to add similar support for UVM on SystemVerilog. Verilog-support.vim currently
supports SystemVerilog and UVM on SV. 

# Features

The verilog-support.vim plugin adds a set of templates that can be used to
insert blocks of code into SystemVerilog files.

* Comment templates: Insert comment headers for Tasks, Functions, Classes, Modules, etc. with menu or hot-key. Comments are suitable for NaturalDoc usage.
* UVM Class templates: Insert class boilerplate for a new UVM class with a menu or hot-key
* UVM Phase templates: Insert the various UVM phase tasks and functions with a menu or hot-key
* UVM idioms template: Insert various UVM code snippets (config_db, objections, etc.) using menu or hot-key.

Templates are user-configurable and extendable. If you have changes that you
think others would find useful, please push them to me.

# Installation

Install to ~/.vim/ directory. 

I highly recommend using Tim Pope's
[pathogen.vim](https://github.com/tpope/vim-pathogen) to manage vim plugins.
Once you have installed that, copy and paste:

    cd ~/.vim/bundle
    git clone git://github.com/jmcneal/verilog-support.git

To pull the latest version of verilog-support directly from Github.

## Configuration

verilog-support automatically inserts several bits of information into comments
and headers in SystemVerilog and Verilog files. These are all set up in the
verilog-support/verilog-support/templates/Templates file. Edit your user name
and such there.

## Dependencies

Although not a dependency, I highly recommend using another plugin to handle
Verilog syntax highlighting and indenting. Vitor Antunes
[verilog_systemverilog.vim](https://github.com/vhda/verilog_systemverilog.vim)
plugin is an excellent choice.

# Release Notes

The verilog-support plugin is still in its early stages, and being actively
developed (on a part-time basis).

# Contact

* Jeff McNeal jeff.mcneal@verilab.com

# License 

GPL version 2
