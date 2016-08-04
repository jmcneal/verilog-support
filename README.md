# verilog-support.vim #

This is a vim plugin that is heavily based on perl-support by Fritz and Wolfgang Mehner. I've followed his architecture and a lot of his code structure to add similar support for UVM on SystemVerilog. Verilog-support.vim currently supports SystemVerilog and UVM on SV. 

### What is this repository for? ###

* Quick summary
* Version 0.5

### How do I get set up? ###

Install to ~/.vim/ directory. 

I highly recommend using Tim Pope's [pathogen.vim](https://github.com/tpope/vim-pathogen) to install in its own directory. Then copy and paste:

    cd ~/.vim/bundle
    git clone git://github.com/jmcneal/verilog-support.git

#### Configuration ####

verilog-support automatically inserts several bits of information into comments and headers in System Verilog and Verilog files. These are all set up in the verilog-support/verilog-support/templates/Templates file. Edit your user name and such there.

* Dependencies
* Database configuration
* How to run tests
* Deployment instructions

### Release Notes ###

The verilog-support plugin is still in its early stages, and being actively developed (on a part-time basis).

### Contribution guidelines ###

* Writing tests
* Code review
* Other guidelines

### Who do I talk to? ###

* Jeff McNeal jeff.mcneal@verilab.com
* Other community or team contact
