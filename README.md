# simple_spec
A lightweight and efficient personal tool for spec driven development (SDD)
This idea was bourne as a way to better study Spec Driven Development and a way to use simpler tools for working with it. Many tools are known to be very verbose, with complex workflows and not token efficient.
This is a little effort to implement what I had in mind.

## Install the initializer

From the root of the downloaded repository, make the script executable and add a `simple-spec` alias to your Zsh configuration with this command:

```sh
chmod +x simple-spec-init.sh && printf '\nalias simple-spec="%s/simple-spec-init.sh"\n' "$PWD" >> ~/.zshrc && source ~/.zshrc
```

Then run `simple-spec` from the project directory where you want Simple Spec files created. The initializer sources its templates from the repository containing the script and will prompt before installing files.
