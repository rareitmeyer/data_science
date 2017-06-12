# Machine Learning Week 11: Photo OCR motivating example

We have many pictures. How can we get computers to read the text
in the image?

Have to find where text is in the image and turn it into a set of text images.
Then have to turn the text area of the image into text.

## Pipeline

Steps

* Find areas of text
* Given rectangle of text, turn it into rectangles for each character
* Classify each character-rectangle into a character
* Spelling correction, if desired

Thinkn of this as a pipeline. In many machine learning systems
pipelines are common.

One of the most important decisions can be figuring out pipeline.
It's common to have different engineers working on different parts of
the pipeline.


## Sliding Windows

### Detecting text regions.

Text detection is hard.

### Pedestrian Problem

Pedestrian detection is easier, because the aspect ratio is pretty much
always the same. So use that as a starting example.

Pick a size and aspect ratio for rectangles that will cover a
pedestrian, perhaps with a little padding.  Call each pedestrian-sized
rectangle a patch, and collect some training examples of patches with
(y=1) and without (y=0) pedestrians.

Train a neural network to classify the patches.

Once the NN is trained, make a mask of the patch size, and use it on a
'big' photo by extracting patch-sized regions of the big photo.  Use
the NN to check each patch to see if the NN thinks it has a
pedestrian.  Then shift the mask by a step size, or stride, and test
again. The step size becomes a model parameter. A step size (stride)
of 1 pixel often works best, but is computationally expensive. So
using a step size of 2-4-8 pixels is common too.

Once you've tried all the patches with the original size, try with a
mask that extracts larger patches, immediately followed by resizing
the extracted piece of the image down to the earlier patch size that
the NN is expecting. Then test all of those.


### Text detection

Similar to pedestrians, train on images with and without text. Perhaps
letter size or so. Scan the whole image and classify if each scanned
region has text or not. Should end up with rectangular regions that
the classifier thinks have text: consider those binary pixels in an
image map. Now we need to group the regions of the image map together
into rectangles with all the contiguous text.

"Expansion operator" helps to merge adjacent regions. For every pixel
is it within N pixels of an 'on' pixel? If so, color 'on.'

Use the expansion operator to pick out connected components via
bounding boxes. Can use hueristics like discarding tall skinny boxes
as unlikely to be text if we like.

Now we can cut out the text regions and use them in later stages of
the pipeline.

### Character segmentation

Now we need to break a rectangular region of text into characters.
Specifically, we want to find the boundaries between letters.  Similar
to before, create a lot of training examples that have boundaries in
the middle, and examples that do not have boundaries in the middle.
(Negative examples could have a letter in the middle, or be completely
blank.)

Now extract more sliding windows, looking for break point between
characters.


## Getting lots of data and artificial data

A low bias algorithm, trained on a lot of data, is a powerful way to
get high predictive power. But getting lots of data is hard.

So synthisize some of the data, where possible.

You can't always do this.

But helpful where you can.

### Synthesis from scratch

Modern computers have big font libraries. If you want more training
examples, paste a character against a random background image, apply
rotation, blurring, etc. It's not trivial to do this well, and if you
do it badly it won't help, but done right it is very useful.

Key is to figure out which things make sense and which do not.


### Via amplification

Amplification: If you are classifing letters and have a picture of an
'a', it is still a picture of an 'a' if you change the aspect ratio,
so synthesize more 'a' pictures by stretching or compressing the 'a'
picture to be taller or shorter.  Same if you do a little rotation, or
apply a blurring filter. Or apply a distortion. Now you have created
many 'a' examples for the classifer out of just a single original
example.


### Speech recognition example

If you have some sample audio data, you can amplify by adding
background noise.


### Cautions / guidance

It's important that whatever distortions are introduced are representative
of the real world.

It usually does not help to add purely random / meaningless noise to
the data.

Make sure you have a low bias classifier before putting in a lot of
effort.  Plot learning curves! If you don't have a low-bias
classifier, keep adding features or hidden units until you do.

Ask: "how long / how much work would it be to get 10x as much data as
we currently have?" If it is not that hard, try to get some.

EG, if it takes 10s to label an example, and you have 1000 examples,
you could get 10x more data in 100,000s. That is roughly 28 hours or
most of a man-week.

In addition to artificial data synthesis, there's always collecting
and labeling youself. Finally you could crowd source (EG, Amazon
Mechanical Turk) to hire people to help you. Mechanical turk can be
hard to get set up with good quality control, but scales very far
inexpensively.


## Ceiling Analysis

Your time is a valuable resource. Don't waste it.

It's frustrating to work hard as a individual or a team and then
find out later that it did not make enough of a difference.

Ceiling analysis can help. Think of the pipeline, and figuring out
which parts of the pipeline you should spend the most time on
improving.

Estimate the errors from each component.

Pick a single overall metric for evaluation and evaluate the current
pipeline.

To check errors from each component, fake a version of the pipeline
where the 1st component is replaced by one that always produces the
right answer (EG, from trained or hand-trained examples). Run the
pipeline from step 2 and record the overall accuracy if component 1
was perfect.

Now create perfect data for the output of component 2, and run the
pipeline from step 3 on. Repeat for all other components, by replacing
the first N components with a single fake step generating 'perfect'
output, and running the remaining steps from N+1 to the end.  Now you
know how much better the pipeline would be if the first N components
were perfect. By differencing those scores you know roughly how much
perfecting a component would be worth in terms of the final score.

These upper bounds help figure out where you should spend your time.

Don't just trust your gut. Prof Ng doesn't trust his....






