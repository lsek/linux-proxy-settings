# linux-proxy-settings

1. Put your settings into `~/.bashrc` or `~/.bash_profile` so you don't have to worry about your settings everytime you open a new terminal window or app!
2. Simply paste the following code at the bottom of your `~/.bashrc` file
3. Then edit the `username`, `password`, `proxy` and `noproxylist` fields in the code you pasted.
4. Open a new terminal
5. Check your settings by running `npm config list` and `cat ~/.npmrc`
6. Try to install your module using `npm install`, or `npm --without-ssl --insecure install` , or override your proxy settings by using `npm --without-ssl --insecure --proxy http://username:password@proxy:8080 install`.
7. If you want the module to be available globally, add option `-g`

## to do
- [x] make repo with proxy settings :tada: :rofl:
- [ ] make bash script
- [ ] make script to install my favorite apps and configs :smiley:
