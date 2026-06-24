function trashutil

    set -l TRASH_DIR "$HOME/.trashfiles"

    mkdir -p "$TRASH_DIR"



    for file in $argv

        if test -e "$file"

            mv "$file" "$TRASH_DIR/"(basename "$file").(date +%s)

            echo "Moved $file to trash."

        else

            echo "$file not found."

        end

    end

end
