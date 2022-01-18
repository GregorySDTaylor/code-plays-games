import sys

pointer = 0
moves = ["d", "r", "u", "l"]
done = False
while not done:
    readLine = sys.stdin.readline().rstrip()
    if readLine == "You win!":
        break
    elif readLine == "You lose!":
        break
    else:
        sys.stdout.write(moves[pointer] + "\n")
        if pointer == len(moves)-1:
            pointer = 0
        else:
            pointer += 1