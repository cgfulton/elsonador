package hello
import (
	"fmt"
	"time"

	"gobot.io/x/gobot"
)

func main() {
	robot := gobot.NewRobot(
		func() {
			gobot.Every(500*time.Millisecond, func() { fmt.Println("Greetings human") })
		},
	)

	robot.Start()
}
