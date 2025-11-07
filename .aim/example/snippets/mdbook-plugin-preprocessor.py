import json
import sys

if **name** == '**main**':
if len(sys.argv) > 1: # we check if we received any argument
if sys.argv[1] == "supports": # then we are good to return an exit status code of 0, since the other argument will just be the renderer's name
sys.exit(0)

    # load both the context and the book representations from stdin
    context, book = json.load(sys.stdin)
    # and now, we can just modify the content of the first chapter
    book['sections'][0]['Chapter']['content'] = '# Hello'
    # we are done with the book's modification, we can just print it to stdout,
    print(json.dumps(book))
