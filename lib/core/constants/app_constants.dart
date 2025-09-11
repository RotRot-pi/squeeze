const appTitle = 'Squeeze';

const supportedExtensions = {'.jpg', '.jpeg', '.png'};

enum JobStatus { queued, processing, done, error }

enum ResizeMode { longEdge, fit, fill, pad }

enum OutputFormat { auto, jpeg, png }

enum ResampleQuality { fast, quality, pixel }
