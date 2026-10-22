// The poster's cover frames: one colour and one thickness for every song. Edit this file to change them.
public let frameHex = "#1F1F1F"
public let frameWidth = 8.0   // points

// The poster background: one flat colour, kept simple so the covers stand out.
public let backgroundHex = "#F7F7F7"

// The vibe forecast. Each genre (as iTunes names it) gives a sky, a feel and an activity.
// The heaviest genre sets the sky and activity, the next sets the feel. Edit freely.
public let weather: [String: (sky: String, feel: String, activity: String)] = [
    "Alternative":  ("Overcast", "brooding", "staring out of windows"),
    "Pop":          ("Bright", "dreamy", "singing in the kitchen"),
    "Electronica":  ("Clear", "buzzy", "walking a little faster"),
    "Dance":        ("Hot", "gusty", "dancing in the hallway"),
    "Soundtrack":   ("Foggy", "cinematic", "narrating your own commute"),
    "Rock":         ("Stormy", "electric", "air guitar"),
    "Hip-Hop/Rap":  ("Humid", "punchy", "nodding along on the bus"),
    "R&B/Soul":     ("Warm", "sultry", "slow cooking"),
    "Jazz":         ("Low cloud", "smoky", "lingering over coffee"),
    "Classical":    ("Still", "crisp", "tidying with intent"),
    "Country":      ("Dry", "sunny", "long drives"),
    "Folk":         ("Mild", "drizzly", "writing in a notebook"),
    "Singer/Songwriter": ("Mild", "tender", "writing in a notebook"),
]
