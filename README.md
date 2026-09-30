Hello!

This is a recreation of the classic flash game Age of war!

[简体中文说明](README_zh-CN.md)

## Built-in localization

The game includes a runtime localization system. It is not a Godot editor plugin and does not require installing an add-on.

Translation data is stored in:

```text
localization/translations.csv
```

The first row defines the language columns. Use the format `locale__display name`:

```csv
keys,en__English,zh_CN__简体中文
```

The first column contains the source text. Each additional column contains one language. To add a language, add a column and fill in its translations:

```csv
keys,en__English,zh_CN__简体中文,ja__日本語
```

The language list in `Options > Language` is generated from the CSV columns. No code changes or Godot plugin installation are required. Empty translations fall back to the source text.

All art assets and sounds were extracted from the original flash game.

The music is Glorious Morning by Waterflame. https://www.youtube.com/watch?v=7T_YtklLyyo

The game can be played here: https://awesomea.itch.io/age-of-war
