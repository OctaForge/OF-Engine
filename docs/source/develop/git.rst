
Git Tutorial
************

Getting started with git can be somewhat tricky, however it is well worth the
short time it takes to learn.

This guide is intended to help you avoid major pitfalls and encourage best
practices related to the CubeCreate repository.


Getting Git
===========

http://git-scm.com/


Windows
-------

1. First you'll need to install mSysGit.  http://msysgit.googlecode.com/
2. Next you can install TortoiseGIT. http://code.google.com/p/tortoisegit/
3. Now before using it ensure you have all the needed options set correctly.

   * Right click (on empty space) -> TortoiseGit -> Settings
   * In General options, in MSysGit field make sure your path is set.
     If it appears to be empty write

     .. code-block :: bash

         C:\Program Files\Git\bin

     .. note::
         This path may be different if you changed the default path.
         Then click "Check now" and it should say version you're using.
         Try reinstalling/rewriting your path if something's gone wrong.


Preparing
=========

Before you can use git you will need to do some basic configuration.
Taking a few minutes to do this now will save you many headaches in the future.
