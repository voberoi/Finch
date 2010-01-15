#import "Sound.h"
#import <AudioToolbox/AudioToolbox.h> 

#define CLEAR_ERROR_FLAG alGetError()
#define DETACH_SOURCE 0

@implementation Sound
@synthesize loop, length, gain;

// Clears the error flag.
- (BOOL) checkSuccessOrLog: (NSString*) msg
{
	ALenum errcode;
	if ((errcode = alGetError()) != AL_NO_ERROR)
	{
		NSLog(@"%@, error code %x.", msg, errcode);
		return NO;
	}
	return YES;
}

#pragma mark Designated Initializer

- (void)cleanUpBuffers
{
	alSourcei(source, AL_BUFFER, DETACH_SOURCE);
	alDeleteBuffers(1, &buffer), buffer = 0;
	alDeleteSources(1, &source), source = 0;
}

- initBuffersAt:(double)fPos
{
	int iPos = iBytesPerSample * (int)round(fPos * (double)frequency);
	if (lastPos != iPos) {
		// Starting from a different location, reset buffer to
		// different position in the data
		
		// Clean up buffers if they were already allocated
		if (lastPos != -1) [self cleanUpBuffers];

		// Allocate new buffer.
		CLEAR_ERROR_FLAG;
		alGenBuffers(1, &buffer);
		if (![self checkSuccessOrLog:@"Failed to allocate OpenAL buffer"])
			return nil;
		
		// Pass sound data to OpenAL.
		CLEAR_ERROR_FLAG;
		alBufferData(buffer, format, data+iPos, size-iPos, frequency);
		if (![self checkSuccessOrLog:@"Failed to fill OpenAL buffers"])
			return nil;
		
		// Initialize the source.
		CLEAR_ERROR_FLAG;
		alGenSources(1, &source);
		
		alSourcei(source, AL_BUFFER, buffer);
		if (![self checkSuccessOrLog:@"Failed to create OpenAL source"])
			return nil;

		lastPos = iPos;
	}
	return self;
}

- (id) initWithData: (ALvoid*) p_data length: (ALsizei) p_size
						 format: (ALenum) p_format sampleRate: (ALsizei) p_frequency 
{
	[super init];
	
	data = p_data;
	size = p_size;
	format = p_format;
	frequency = p_frequency;
	if (format == AL_FORMAT_MONO8) {
	  iBytesPerSample = 1;
	} else if (format == AL_FORMAT_MONO16) {
	  iBytesPerSample = 2;
	} else if (format == AL_FORMAT_STEREO8) {
	  iBytesPerSample = 2;
	} else if (format == AL_FORMAT_STEREO16) {
	  iBytesPerSample = 4;
	} else {
		NSLog(@"Unknown format %d?", format);
		return nil;
	}
	lastPos = -1;
	
	ALCcontext *const currentContext = alcGetCurrentContext();
	if (currentContext == NULL)
	{
		NSLog(@"OpenAL context not set, did you initialize Finch?");
		return nil;
	}
	[self initBuffersAt:0.0];
	
	gain = 1;
	return self;
}

- (void) dealloc
{
	[self stop];
	CLEAR_ERROR_FLAG;
	free(data);
	[self cleanUpBuffers];
	[self checkSuccessOrLog:@"Failed to clean up after sound"];
	[super dealloc];
}

#pragma mark Playback Controls

- (void) setGain: (float) val
{
	gain = val;
	alSourcef(source, AL_GAIN, gain);
}

- (BOOL) playing
{
	ALint state;
	alGetSourcei(source, AL_SOURCE_STATE, &state);
	return (state == AL_PLAYING);
}

- (void) setLoop: (BOOL) yn
{
	loop = yn;
	alSourcei(source, AL_LOOPING, yn);
}

- (void) playFrom:(double)fPos
{
	if (self.playing)
		[self stop];
	CLEAR_ERROR_FLAG;
	[self initBuffersAt:fPos];
	alSourcePlay(source);
	[self checkSuccessOrLog:@"Failed to start sound"];
}

- (void) play
{
	[self playFrom:0.0];
}

- (void) stop
{
	if (!self.playing)
		return;
	CLEAR_ERROR_FLAG;
	alSourceStop(source);
	[self checkSuccessOrLog:@"Failed to stop sound"];
}

@end
