"""
This script splits a large video into 8 roughly equal segments, processes them concurrently on 8 separate GPUs, 
and then concatenates them back together. It uses the `moviepy` library to split and concatenate the videos, 
and Python's `subprocess` module to call the `transparent-background` command line tool for video processing. 
The `transparent-background` tool is assumed to be in the system's PATH. The script also assumes that 8 GPUs are available 
and uses the `concurrent.futures` module to manage the concurrent processing tasks.
"""

# USAGE: python multi_gpu_transparent_background.py [filename]
import os
import subprocess
import sys
from moviepy.video.io.ffmpeg_tools import ffmpeg_extract_subclip
from moviepy.editor import concatenate_videoclips, VideoFileClip
from concurrent.futures import ThreadPoolExecutor

def split_video(filename, num_parts):
    clip = VideoFileClip(filename)
    duration = clip.duration
    part_duration = duration / num_parts
    parts = []
    
    for i in range(num_parts):
        start_time = i * part_duration
        end_time = (i + 1) * part_duration if i < num_parts - 1 else duration
        part_filename = f"{filename}_{i}.mp4"
        ffmpeg_extract_subclip(filename, start_time, end_time, targetname=part_filename)
        parts.append(part_filename)
    
    return parts

def process_video(part_filename, gpu_id):
    output_filename = f"{part_filename}_map.mp4"
    cmd = f"CUDA_VISIBLE_DEVICES={gpu_id} transparent-background --jit --type map --source {part_filename}"
    subprocess.run(cmd, shell=True)
    return output_filename

def concatenate_videos(filenames, output_filename):
    clips = [VideoFileClip(filename) for filename in filenames]
    final_clip = concatenate_videoclips(clips)
    final_clip.write_videofile(output_filename, codec='libx264')

def main():
    filename = sys.argv[1]  # replace with your video file url
    num_parts = 8
    output_filename = f"{filename}_final.mp4"
    
    # Split video
    parts = split_video(filename, num_parts)
    
    # Process video parts on different GPUs concurrently
    with ThreadPoolExecutor(max_workers=num_parts) as executor:
        futures = [executor.submit(process_video, part, i % num_parts) for i, part in enumerate(parts)]
        processed_parts = [future.result() for future in futures]
    
    # Concatenate processed parts
    concatenate_videos(processed_parts, output_filename)

if __name__ == "__main__":
    main()
