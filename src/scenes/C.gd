extends Node

# C for "constants"

const OBJECT_REACHED_DISTANCE = 9

const CURSOR_POINTER = 0
const CURSOR_INSPECT = 1

const JOB_NO_CHANGE = -1
const JOB_NONE = 0
const JOB_FARMER = 1
const JOB_LUMBERJACK = 2
const JOB_SLEEPER = 3 # when too tired
const JOB_EATER = 4 # when too hungry
const JOB_FIRESTARTER = 5 # twisted

const TASK_IDLING = 0
const TASK_COLLECTING = 1
const TASK_DROPPING_OFF = 2
const TASK_SEEDING = 3
const TASK_WATERING_1 = 4
const TASK_WATERING_2 = 5
const TASK_CHOPPING_TREE = 6
const TASK_SLEEPING = 7
const TASK_EATING = 8
const TASK_STARTING_THE_FIRE = 9 # we did (not) start it...
const TASK_FLEE = 10 # go back to safety

const COLOR_JOB_INACTIVE = Color(0.8, 0.8, 0.8, 1.0)
const COLOR_JOB_CURRENT = Color(0.0, 1.0, 0.0, 1.0)
const COLOR_JOB_NEW = Color(0.2, 0.6, 0.2, 1.0)

const COLOR_MENU_ACTIVE = Color(1.0, 1.0, 1.0, 1.0)
const COLOR_MENU_INACTIVE = Color(0.7, 0.7, 0.7, 1.0)
