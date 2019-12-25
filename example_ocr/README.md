# OCR demo

The IDHash is not designed for OCR in the first place but in specific cases it might work well. You might also consider using it because the algorithm is enough simple so the built solution won't be a magic black box for you.

The following image was rendered at https://www.fonts.com/font/monotype/arial/light:

![](https://storage.googleapis.com/dhash-vips.nakilon.pro/monotype-arial.png)

The program renders 26 upper case chars of each font you want using your OS fonts and compares them with each char detected on the image.  
This isn't made to break captchas so it assumes that chars are clearly whitespace separated, not rotated, black-on-white, etc. At the end it recognizes it as:

```
$ bundle install --without development
$ bundle exec ruby main.rb

THEQUIOKBROWNHOXUUVPS
OVERTHELAZYDOG
```

In case when you have access to the exact font that was used to render the input image it should not have errors at all but here we have some.  
For some reason `I` of Arial on my OS and on the website are different (this is partially why Menlo gave the best result while other fonts confused `I` with `T`) -- maybe the font weight matters and maybe you need to add a white border around glyphs. It's possible to improve the result by trying different fonts and combining results in smart ways. Also you can recognise space characters to split by words and then use the English dictionary to reject what does not make sense.

So there is a lot of room for improvement as an OCR tool but this is just an example of code using the `dhash-vips` gem -- `ctrl+F` the `DHashVips::IDHash` to see lines where it's used.
