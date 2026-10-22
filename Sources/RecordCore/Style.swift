// The poster's cover frames: one colour and one thickness for every song. Edit this file to change them.
public let frameHex = "#1F1F1F"
public let frameWidth = 8.0   // points

// The poster background: one flat colour, kept simple so the covers stand out.
public let backgroundHex = "#E8E4DE"

// The vibe forecast. Apple Music and iTunes name genres in over a hundred ways, so each name is mapped to one of
// 18 families below, and each family has four skies, four feelings and four activities to draw from.
// Edit freely: add a genre name to `genreNames`, or new words to a family. Keep each phrase short.
public struct WeatherWords {
    public let label: String                // how the family is named in a sentence
    public let skies: [String], feels: [String], activities: [String]
}

public let weather: [String: WeatherWords] = [
    "alternative": WeatherWords(label: "alternative", skies: ["Overcast", "Cloudy", "Low cloud", "Gloomy"],
        feels: ["brooding", "moody", "restless", "wistful"],
        activities: ["staring out of windows", "rereading old messages", "wandering with headphones on", "making a playlist at 2am"]),
    "pop": WeatherWords(label: "pop", skies: ["Bright", "Sunny", "Clear", "Sun-drenched"],
        feels: ["dreamy", "bouncy", "giddy", "glossy"],
        activities: ["singing in the kitchen", "dancing while the kettle boils", "humming on the way to work", "replaying the chorus"]),
    "indie": WeatherWords(label: "indie", skies: ["Hazy", "Patchy", "Lightly clouded", "Softly lit"],
        feels: ["wistful", "jangly", "tender", "scrappy"],
        activities: ["making a mixtape", "lying on the floor", "texting a friend a link", "wearing the same hoodie all week"]),
    "hiphop": WeatherWords(label: "hip-hop", skies: ["Humid", "Hot", "Muggy", "Warm and clear"],
        feels: ["punchy", "confident", "loose", "sharp"],
        activities: ["nodding along on the bus", "rapping in the shower", "walking with swagger", "looping the same verse"]),
    "electronic": WeatherWords(label: "electronic", skies: ["Clear", "Crisp", "Cold and bright", "Neon-bright"],
        feels: ["buzzy", "pulsing", "glitchy", "cool"],
        activities: ["walking a little faster", "tidying to a beat", "working with headphones on", "staying up late"]),
    "dance": WeatherWords(label: "dance", skies: ["Hot", "Sweltering", "Sultry", "Sticky"],
        feels: ["gusty", "sweaty", "electric", "euphoric"],
        activities: ["dancing in the hallway", "cleaning at full volume", "getting ready too early", "leaving the party last"]),
    "rnb": WeatherWords(label: "soul", skies: ["Warm", "Balmy", "Mellow", "Soft and warm"],
        feels: ["sultry", "smooth", "slow", "tender"],
        activities: ["slow cooking", "lighting a candle", "texting someone back", "taking the long way home"]),
    "rock": WeatherWords(label: "rock", skies: ["Stormy", "Thundery", "Squally", "Gusty"],
        feels: ["electric", "raw", "loud", "feral"],
        activities: ["air guitar", "driving with the windows down", "turning it up", "hunting for the guitar solo"]),
    "metal": WeatherWords(label: "metal", skies: ["Thunderous", "Pitch dark", "Ominous", "Hail-prone"],
        feels: ["relentless", "heavy", "fierce", "bruising"],
        activities: ["headbanging at the desk", "lifting something heavy", "turning it all the way up", "cleaning the whole house"]),
    "soundtrack": WeatherWords(label: "soundtrack", skies: ["Foggy", "Misty", "Hazy", "Low fog"],
        feels: ["cinematic", "dramatic", "sweeping", "lingering"],
        activities: ["narrating your own commute", "staring dramatically into the distance", "walking in slow motion", "imagining the credits"]),
    "folk": WeatherWords(label: "folk", skies: ["Mild", "Fresh", "Drizzly", "Soft-lit"],
        feels: ["tender", "honest", "gentle", "wistful"],
        activities: ["writing in a notebook", "walking the long way", "making soup", "sitting by a window"]),
    "jazz": WeatherWords(label: "jazz", skies: ["Low cloud", "Smoky", "Rain-soaked", "Dimly lit"],
        feels: ["smoky", "loose", "mellow", "unhurried"],
        activities: ["lingering over coffee", "reading with the lamp on", "cooking something slow", "taking it easy"]),
    "classical": WeatherWords(label: "classical", skies: ["Still", "Calm", "Crisp", "Quiet"],
        feels: ["crisp", "serene", "measured", "stately"],
        activities: ["tidying with intent", "reading in silence", "working in deep focus", "sorting the bookshelf"]),
    "ambient": WeatherWords(label: "ambient", skies: ["Lightly hazy", "Drifting", "Softly fogged", "Still"],
        feels: ["drifting", "weightless", "hushed", "slow"],
        activities: ["lying very still", "staring at the ceiling", "falling asleep early", "working without noticing"]),
    "latin": WeatherWords(label: "latin", skies: ["Hot", "Sunny", "Balmy", "Steamy"],
        feels: ["swaying", "lively", "warm", "sunlit"],
        activities: ["dancing in the kitchen", "cooking for too many people", "singing along badly", "taking the long way to the beach"]),
    "world": WeatherWords(label: "world", skies: ["Breezy", "Bright", "Dry and hot", "Clear"],
        feels: ["rolling", "sunlit", "buoyant", "far-flung"],
        activities: ["planning a trip", "walking in the sun", "cooking something new", "dancing on a Tuesday"]),
    "country": WeatherWords(label: "country", skies: ["Dry", "Wide open", "Clear", "Dusty"],
        feels: ["easy", "wistful", "sunny", "twangy"],
        activities: ["long drives", "sitting on the porch", "humming at the sink", "watching the sun go down"]),
    "reggae": WeatherWords(label: "reggae", skies: ["Warm", "Balmy", "Showery", "Sunny"],
        feels: ["easy", "sunlit", "lazy", "laid-back"],
        activities: ["lingering in the sun", "not rushing anything", "taking a long lunch", "swaying in the doorway"]),
]

/// Used when none of the songs has a genre we know, so a week still gets a line.
public let neutralWeather = WeatherWords(label: "mixed", skies: ["Mixed", "Variable", "Patchy", "Hazy"],
    feels: ["easygoing", "settled", "unhurried", "wandering"],
    activities: ["making tea", "going for a walk", "tidying up", "looking out of the window"])

// Genre names as Apple Music and iTunes write them (lower case) and the family each belongs to.
// A name that isn't here is matched by keyword (see `family(of:)`), then falls back to the neutral words.
public let genreNames: [String: String] = [
    "alternative": "alternative", "adult alternative": "alternative", "alternative rock": "alternative",
    "pop": "pop", "k-pop": "pop", "french pop": "pop", "dance pop": "pop",
    "indie pop": "indie", "indie rock": "indie",
    "hip-hop/rap": "hiphop", "hip-hop": "hiphop", "rap": "hiphop", "alternative rap": "hiphop", "hip hop": "hiphop",
    "electronic": "electronic", "electronica": "electronic", "techno": "electronic", "dubstep": "electronic",
    "bass": "electronic", "jungle/drum'n'bass": "electronic", "idm": "electronic", "trance": "electronic",
    "dance": "dance", "house": "dance",
    "r&b/soul": "rnb", "soul": "rnb", "neo-soul": "rnb", "contemporary r&b": "rnb", "r&b": "rnb",
    "rock": "rock", "punk": "rock", "classic rock": "rock", "soft rock": "rock",
    "metal": "metal", "hard rock": "metal", "heavy metal": "metal",
    "soundtrack": "soundtrack",
    "folk": "folk", "alternative folk": "folk", "contemporary folk": "folk", "singer/songwriter": "folk",
    "jazz": "jazz", "blues": "jazz", "bossa nova": "jazz",
    "classical": "classical", "classical crossover": "classical", "opera": "classical",
    "ambient": "ambient", "new age": "ambient", "downtempo": "ambient", "instrumental": "ambient",
    "latin": "latin", "pop latino": "latin", "urbano latino": "latin", "mpb": "latin", "reggaeton": "latin", "salsa": "latin",
    "worldwide": "world", "world": "world", "afrobeats": "world",
    "country": "country", "reggae": "reggae",
]
